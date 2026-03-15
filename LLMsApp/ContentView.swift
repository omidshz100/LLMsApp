//
//  ContentView.swift
//  LLMsApp
//
//  Created by Omid Shojaeian Zanjani on 14/03/26.
//

import SwiftUI
import Foundation
import SwiftLlama

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
}

final class MockLLMEngine: LLMEngine {
    private var llamaService: LlamaService?
    private var streamTask: Task<Void, Never>?
    private let settings: ModelSettings
    
    init(settings: ModelSettings) {
        self.settings = settings
    }

    func loadModel(from path: String) async throws {
        let modelUrl = URL(fileURLWithPath: path)
        let config = LlamaConfig(
            batchSize: UInt32(settings.batchSize),
            maxTokenCount: UInt32(settings.maxTokenCount),
            useGPU: settings.useGPU
        )
        llamaService = LlamaService(modelUrl: modelUrl, config: config)
    }

    func unloadModel() async throws {
        // Cancel any ongoing generation first
        streamTask?.cancel()
        streamTask = nil
        // Release the service to free memory
        llamaService = nil
        // Give system time to reclaim memory
        try await Task.sleep(nanoseconds: 100_000_000)
    }

    func generate(prompt: String, tokenHandler: @escaping (String) -> Bool) async throws {
        guard let service = llamaService else {
            throw ModelAdapterError.modelNotLoaded
        }

        // Build messages array with optional system prompt
        var messages: [LlamaChatMessage] = []
        if settings.useSystemPrompt {
            messages.append(LlamaChatMessage(role: .system, content: settings.systemPrompt))
        }
        messages.append(LlamaChatMessage(role: .user, content: prompt))
        
        // Create sampling config from settings
        let samplingConfig = LlamaSamplingConfig(
            temperature: settings.temperature,
            seed: settings.seed,
            topP: settings.topP,
            topK: settings.topK,
            minKeep: settings.minKeep,
            grammarConfig: nil,
            repetitionPenaltyConfig: settings.enableRepetitionPenalty ?
                LlamaRepetitionPenaltyConfig(
                    lastN: Int32(settings.penaltyLastN),
                    repeatPenalty: settings.repetitionPenalty,
                    freqPenalty: settings.frequencyPenalty,
                    presentPenalty: settings.presencePenalty
                ) : nil
        )

        let stream = try await service.streamCompletion(of: messages, samplingConfig: samplingConfig)

        for try await token in stream {
            let shouldContinue = tokenHandler(token)
            if !shouldContinue || Task.isCancelled {
                break
            }
        }
    }

    func cancelGeneration() {
        streamTask?.cancel()
    }
}
