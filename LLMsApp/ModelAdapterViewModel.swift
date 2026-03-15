//
//  ModelAdapter.swift
//  LLMsApp
//
//  Created by Omid Shojaeian Zanjani on 14/03/26.
//

import Foundation
import Combine

/// Protocol describing the minimal model engine operations we expect.
/// Implement this protocol to adapt any LLM backend (e.g. swift-llama-cpp wrapper).
public protocol LLMEngine {
    /// Load a model from disk. Returns asynchronously when ready or throws an error.
    func loadModel(from path: String) async throws

    /// Unload and free resources held by the engine.
    func unloadModel() async throws

    /// Generate text for a given prompt. The engine may call the provided tokenHandler repeatedly as tokens arrive.
    /// - Parameters:
    ///   - prompt: input text prompt
    ///   - tokenHandler: called for each token (or chunk) produced. Return `true` to continue, `false` to cancel generation early.
    /// - Throws: an error if generation cannot start
    func generate(prompt: String, tokenHandler: @escaping (_ token: String) -> Bool) async throws

    /// Cancel any in-flight generation. This should cause the ongoing `generate` call to return promptly.
    func cancelGeneration()
}

/// Simple error type for model adapter operations.
public enum ModelAdapterError: Error, LocalizedError {
    case modelNotLoaded
    case engineError(String)

    public var errorDescription: String? {
        switch self {
        case .modelNotLoaded: return "Model is not loaded"
        case .engineError(let msg): return msg
        }
    }
}

/// A lightweight view-model that wraps an `LLMEngine` implementation.
/// It exposes loading, generating and cancellation APIs, and publishes status updates suitable for SwiftUI.
public final class ModelAdapterViewModel: ObservableObject {
    // MARK: - Published state
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var isGenerating: Bool = false
    @Published public private(set) var generatedText: String = ""
    @Published public private(set) var lastError: Error?

    // Optional progress/diagnostics
    @Published public private(set) var progressDescription: String? = nil

    // MARK: - Dependencies
    internal let engine: LLMEngine

    // Keep track of a simple task so we can cancel/observe it
    private var generationTask: Task<Void, Never>? = nil

    // MARK: - Initialization
    public init(engine: LLMEngine) {
        self.engine = engine
    }

    // MARK: - Model lifecycle
    /// Load the model at the given path. This toggles `isLoading` and clears previous errors.
    @MainActor
    public func loadModel(at path: String) async {
        lastError = nil
        isLoading = true
        do {
            try await engine.loadModel(from: path)
        } catch {
            lastError = error
        }
        isLoading = false
    }

    /// Unload the model and reset state.
    @MainActor
    public func unloadModel() async {
        lastError = nil
        isLoading = true
        do {
            try await engine.unloadModel()
            // reset generated text
            generatedText = ""
        } catch {
            lastError = error
        }
        isLoading = false
    }

    // MARK: - Generation
    /// Start generating for the provided prompt. Tokens are appended to `generatedText` and published.
    /// If a generation is already in progress it will be cancelled first.
    @MainActor
    public func generate(prompt: String) {
        guard !isLoading else { return }

        // Cancel existing generation if any
        cancelGeneration()

        lastError = nil
        generatedText = ""
        isGenerating = true

        generationTask = Task { [weak self] in
            guard let self = self else { return }

            do {
                try await self.engine.generate(prompt: prompt) { token in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        self.generatedText.append(token)
                    }
                    return !Task.isCancelled
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.lastError = error
                }
            }

            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.isGenerating = false
                self.generationTask = nil
            }
        }
    }

    /// Cancel any in-progress generation.
    @MainActor
    public func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        engine.cancelGeneration()
        isGenerating = false
    }

    // MARK: - Convenience helpers
    public var canGenerate: Bool {
        !isLoading && !isGenerating
    }

    // MARK: - Convenience loading from bundle
    @MainActor
    public func loadModelFromBundle(named modelNameOrFile: String) async {
        lastError = nil

        let ext = "gguf"
        let resourceName: String
        if modelNameOrFile.lowercased().hasSuffix(".\(ext)") {
            resourceName = String(modelNameOrFile.dropLast(ext.count + 1))
        } else {
            resourceName = modelNameOrFile
        }

        guard let modelUrl = Bundle.main.url(forResource: resourceName, withExtension: ext) else {
            lastError = ModelAdapterError.engineError("Model '\(modelNameOrFile)' not found in bundle")
            return
        }

        await loadModel(at: modelUrl.path)
    }
}
