//
//  DocumentModel.swift
//  LLMsApp
//
//  Created by Omid Shojaeian Zanjani on 15/03/26.
//

import Foundation

/// Represents a text chunk with its embedding
struct DocumentChunk: Identifiable, Codable {
    let id: UUID
    let text: String
    let embedding: [Float]
    let chunkIndex: Int
    
    init(id: UUID = UUID(), text: String, embedding: [Float], chunkIndex: Int) {
        self.id = id
        self.text = text
        self.embedding = embedding
        self.chunkIndex = chunkIndex
    }
}

/// Represents a document with its chunks and metadata
struct DocumentModel: Identifiable, Codable {
    let id: UUID
    var fileName: String
    var fileType: DocumentType
    var dateAdded: Date
    var chunks: [DocumentChunk]
    var totalChunks: Int {
        chunks.count
    }
    
    init(id: UUID = UUID(), fileName: String, fileType: DocumentType, dateAdded: Date = Date(), chunks: [DocumentChunk] = []) {
        self.id = id
        self.fileName = fileName
        self.fileType = fileType
        self.dateAdded = dateAdded
        self.chunks = chunks
    }
}

enum DocumentType: String, Codable {
    case pdf = "PDF"
    case text = "TXT"
    
    var icon: String {
        switch self {
        case .pdf: return "doc.fill"
        case .text: return "doc.text.fill"
        }
    }
}

/// Chat message for document conversations
struct DocumentChatMessage: Identifiable, Codable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
    var sources: [Int] // Chunk indices used for this response
    
    init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date = Date(), sources: [Int] = []) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
        self.sources = sources
    }
}
