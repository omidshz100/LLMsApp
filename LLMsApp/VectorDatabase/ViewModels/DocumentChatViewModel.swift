//
//  DocumentChatViewModel.swift
//  LLMsApp
//
//  Created by Omid Shojaeian Zanjani on 15/03/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DocumentChatViewModel: ObservableObject {
    @Published var messages: [DocumentChatMessage] = []
    @Published var isGenerating: Bool = false
    @Published var lastError: Error?
    @Published var currentResponse: String = ""
    
    private let document: DocumentModel
    private let databaseManager: VectorDatabaseManager
    private let llmViewModel: ModelAdapterViewModel
    private var generationTask: Task<Void, Never>?
    
    init(document: DocumentModel, databaseManager: VectorDatabaseManager, llmViewModel: ModelAdapterViewModel) {
        self.document = document
        self.databaseManager = databaseManager
        self.llmViewModel = llmViewModel
        
        // Add welcome message
        messages.append(DocumentChatMessage(
            text: "Hi! I'm ready to answer questions about '\(document.fileName)'. Ask me anything!",
            isUser: false
        ))
    }
    
    // MARK: - Chat Operations
    
    func sendMessage(_ text: String) {
        let userMessage = DocumentChatMessage(text: text, isUser: true)
        messages.append(userMessage)
        
        // Start RAG-powered generation
        generateRAGResponse(for: text)
    }
    
    func cancelGeneration() {
        generationTask?.cancel()
        llmViewModel.cancelGeneration()
        isGenerating = false
    }
    
    // MARK: - RAG Implementation
    
    private func generateRAGResponse(for query: String) {
        isGenerating = true
        currentResponse = ""
        lastError = nil
        
        generationTask = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                // 1. Search for relevant chunks
                let results = try await self.databaseManager.searchSimilarChunks(
                    in: self.document.id,
                    query: query,
                    topK: 3
                )
                
                guard !results.isEmpty else {
                    await self.addAIMessage("I couldn't find relevant information in the document to answer your question.")
                    self.isGenerating = false
                    return
                }
                
                // 2. Build context from retrieved chunks
                let context = results.enumerated().map { index, result in
                    "Context \(index + 1) (similarity: \(String(format: "%.2f", result.similarity))):\n\(result.chunk.text)"
                }.joined(separator: "\n\n")
                
                // 3. Build RAG prompt
                let ragPrompt = """
                Based on the following context from the document, answer the user's question. If the context doesn't contain relevant information, say so.
                
                Context:
                \(context)
                
                Question: \(query)
                
                Answer:
                """
                
                // 4. Store source chunk indices
                let sourceIndices = results.map { $0.chunk.chunkIndex }
                
                // 5. Generate response using LLM
                // Add placeholder for AI message
                let aiMessage = DocumentChatMessage(text: "", isUser: false, sources: sourceIndices)
                await MainActor.run {
                    self.messages.append(aiMessage)
                }
                
                // Generate using existing LLM
                try await self.llmViewModel.engine.generate(prompt: ragPrompt) { [weak self] token in
                    guard let self = self else { return false }
                    
                    Task { @MainActor in
                        self.currentResponse += token
                        self.updateLastAIMessage()
                    }
                    
                    return !Task.isCancelled
                }
                
                await MainActor.run {
                    self.isGenerating = false
                    self.currentResponse = ""
                }
                
            } catch {
                await MainActor.run {
                    self.lastError = error
                    self.isGenerating = false
                    self.addAIMessage("Sorry, I encountered an error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateLastAIMessage() {
        guard !messages.isEmpty, !messages.last!.isUser else { return }
        
        let lastMessage = messages[messages.count - 1]
        messages[messages.count - 1] = DocumentChatMessage(
            id: lastMessage.id,
            text: currentResponse,
            isUser: false,
            timestamp: lastMessage.timestamp,
            sources: lastMessage.sources
        )
    }
    
    private func addAIMessage(_ text: String, sources: [Int] = []) {
        messages.append(DocumentChatMessage(
            text: text,
            isUser: false,
            sources: sources
        ))
    }
}
