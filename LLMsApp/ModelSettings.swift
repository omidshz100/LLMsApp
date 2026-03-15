//
//  ModelSettings.swift
//  LLMsApp
//
//  Created by Omid Shojaeian Zanjani on 15/03/26.
//

import Foundation
import SwiftUI
import Combine

/// Holds all configurable model parameters
public class ModelSettings: ObservableObject {
    // MARK: - Model Configuration
    @Published public var batchSize: Int = 64
    @Published public var maxTokenCount: Int = 256
    @Published public var useGPU: Bool = false
    
    // MARK: - Sampling Configuration
    @Published public var temperature: Float = 0.8
    @Published public var seed: UInt32 = 42
    @Published public var topP: Float = 0.95
    @Published public var topK: Int32? = nil
    @Published public var minKeep: Int = 1
    
    // MARK: - Repetition Penalty
    @Published public var enableRepetitionPenalty: Bool = true
    @Published public var repetitionPenalty: Float = 1.1
    @Published public var frequencyPenalty: Float = 0.0
    @Published public var presencePenalty: Float = 0.0
    @Published public var penaltyLastN: Int = 64
    
    // MARK: - System Prompt
    @Published public var systemPrompt: String = "You are a helpful assistant."
    @Published public var useSystemPrompt: Bool = false
    
    public init() {}
    
    /// Reset all settings to defaults
    public func resetToDefaults() {
        batchSize = 64
        maxTokenCount = 256
        useGPU = false
        temperature = 0.8
        seed = 42
        topP = 0.95
        topK = nil
        minKeep = 1
        enableRepetitionPenalty = true
        repetitionPenalty = 1.1
        frequencyPenalty = 0.0
        presencePenalty = 0.0
        penaltyLastN = 64
        systemPrompt = "You are a helpful assistant."
        useSystemPrompt = false
    }
}
