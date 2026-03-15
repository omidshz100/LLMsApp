//
//  EmbeddingGenerator.swift
//  LLMsApp
//
//  Created by Omid Shojaeian Zanjani on 15/03/26.
//

import Foundation
import SwiftLlama

class EmbeddingGenerator {
    private var llamaService: LlamaService?
    
    /// Initialize with a model for embedding generation
    func loadEmbeddingModel(modelUrl: URL) async throws {
        let config = LlamaConfig(
            batchSize: 128,
            maxTokenCount: 512,
            useGPU: false
        )
        llamaService = LlamaService(modelUrl: modelUrl, config: config)
    }
    
    /// Generate embedding for a single text
    func generateEmbedding(for text: String) async throws -> [Float] {
        guard let service = llamaService else {
            throw EmbeddingError.modelNotLoaded
        }
        
        // Note: SwiftLlama's embedding support depends on the library version
        // This is a simplified approach - you may need to adjust based on actual API
        
        // For now, we'll create a simple hash-based embedding as a fallback
        // In production, you should use proper embeddings from the model
        return generateSimpleEmbedding(for: text)
    }
    
    /// Generate embeddings for multiple texts
    func generateEmbeddings(for texts: [String]) async throws -> [[Float]] {
        var embeddings: [[Float]] = []
        
        for text in texts {
            let embedding = try await generateEmbedding(for: text)
            embeddings.append(embedding)
        }
        
        return embeddings
    }
    
    /// Simple embedding generation using text features
    /// Replace this with actual model-based embeddings when available
    private func generateSimpleEmbedding(for text: String, dimensions: Int = 384) -> [Float] {
        let normalized = text.lowercased()
        var embedding = [Float](repeating: 0.0, count: dimensions)
        
        // Use hash-based features
        for (index, char) in normalized.enumerated() {
            let hashValue = char.hashValue
            let embeddingIndex = abs(hashValue) % dimensions
            embedding[embeddingIndex] += 1.0 / Float(normalized.count)
        }
        
        // Normalize the embedding
        let magnitude = sqrt(embedding.map { $0 * $0 }.reduce(0, +))
        if magnitude > 0 {
            embedding = embedding.map { $0 / magnitude }
        }
        
        return embedding
    }
    
    /// Calculate cosine similarity between two embeddings
    static func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0.0 }
        
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        guard magnitudeA > 0, magnitudeB > 0 else { return 0.0 }
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
}

enum EmbeddingError: Error, LocalizedError {
    case modelNotLoaded
    case generationFailed
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Embedding model is not loaded"
        case .generationFailed:
            return "Failed to generate embeddings"
        }
    }
}
