//
//  VectorDatabaseManager.swift
//  LLMsApp
//
//  Created by Omid Shojaeian Zanjani on 15/03/26.
//

import Foundation
import Combine

/// Manages document storage and vector search operations
class VectorDatabaseManager: ObservableObject {
    @Published private(set) var documents: [DocumentModel] = []
    
    private let embeddingGenerator = EmbeddingGenerator()
    private let userDefaultsKey = "stored_documents"
    
    init() {
        loadDocuments()
    }
    
    // MARK: - Document Management
    
    /// Add a new document with chunks and embeddings
    func addDocument(_ document: DocumentModel) {
        documents.append(document)
        saveDocuments()
    }
    
    /// Remove a document by ID
    func removeDocument(id: UUID) {
        documents.removeAll { $0.id == id }
        saveDocuments()
    }
    
    /// Get document by ID
    func getDocument(id: UUID) -> DocumentModel? {
        return documents.first { $0.id == id }
    }
    
    // MARK: - Import Operations
    
    /// Import a PDF file and create document with embeddings
    func importPDF(url: URL) async throws -> DocumentModel {
        do {
            // Extract text from PDF
            let text = try PDFProcessor.extractText(from: url)
            
            // Chunk the text
            let textChunks = PDFProcessor.chunkText(text, chunkSize: 500, overlap: 50)
            
            // Generate embeddings for each chunk
            let embeddings = try await embeddingGenerator.generateEmbeddings(for: textChunks)
            
            // Create document chunks
            let chunks = zip(textChunks, embeddings).enumerated().map { index, pair in
                DocumentChunk(
                    text: pair.0,
                    embedding: pair.1,
                    chunkIndex: index
                )
            }
            
            // Create document
            let document = DocumentModel(
                fileName: url.lastPathComponent,
                fileType: .pdf,
                chunks: chunks
            )
            
            // Clean up temporary file if it's in temp directory
            cleanupTemporaryFile(url: url)
            
            return document
            
        } catch {
            // Clean up temporary file on error
            cleanupTemporaryFile(url: url)
            throw VectorDatabaseError.importFailed("PDF processing failed: \(error.localizedDescription)")
        }
    }
    
    /// Import a text file and create document with embeddings
    func importTextFile(url: URL) async throws -> DocumentModel {
        do {
            // Extract text from file
            let text = try PDFProcessor.extractTextFromFile(url: url)
            
            // Chunk the text
            let textChunks = PDFProcessor.chunkText(text, chunkSize: 500, overlap: 50)
            
            // Generate embeddings for each chunk
            let embeddings = try await embeddingGenerator.generateEmbeddings(for: textChunks)
            
            // Create document chunks
            let chunks = zip(textChunks, embeddings).enumerated().map { index, pair in
                DocumentChunk(
                    text: pair.0,
                    embedding: pair.1,
                    chunkIndex: index
                )
            }
            
            // Create document
            let document = DocumentModel(
                fileName: url.lastPathComponent,
                fileType: .text,
                chunks: chunks
            )
            
            // Clean up temporary file if it's in temp directory
            cleanupTemporaryFile(url: url)
            
            return document
            
        } catch {
            // Clean up temporary file on error
            cleanupTemporaryFile(url: url)
            throw VectorDatabaseError.importFailed("Text file processing failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Clean up temporary files after processing
    private func cleanupTemporaryFile(url: URL) {
        // Only clean up files in the temporary directory
        let tempDirectory = FileManager.default.temporaryDirectory
        if url.path.hasPrefix(tempDirectory.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    // MARK: - Vector Search
    
    /// Search for similar chunks in a document
    func searchSimilarChunks(in documentId: UUID, query: String, topK: Int = 3) async throws -> [(chunk: DocumentChunk, similarity: Float)] {
        guard let document = getDocument(id: documentId) else {
            throw VectorDatabaseError.documentNotFound
        }
        
        // Generate embedding for query
        let queryEmbedding = try await embeddingGenerator.generateEmbedding(for: query)
        
        // Calculate similarity scores for all chunks
        var results: [(chunk: DocumentChunk, similarity: Float)] = []
        
        for chunk in document.chunks {
            let similarity = EmbeddingGenerator.cosineSimilarity(queryEmbedding, chunk.embedding)
            results.append((chunk: chunk, similarity: similarity))
        }
        
        // Sort by similarity (descending) and take top K
        results.sort { $0.similarity > $1.similarity }
        return Array(results.prefix(topK))
    }
    
    // MARK: - Persistence
    
    private func saveDocuments() {
        if let encoded = try? JSONEncoder().encode(documents) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadDocuments() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([DocumentModel].self, from: data) {
            documents = decoded
        }
    }
}

enum VectorDatabaseError: Error, LocalizedError {
    case documentNotFound
    case importFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .documentNotFound:
            return "Document not found"
        case .importFailed(let reason):
            return "Import failed: \(reason)"
        }
    }
}
