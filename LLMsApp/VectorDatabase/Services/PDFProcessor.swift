//
//  PDFProcessor.swift
//  LLMsApp
//
//  Created by Omid Shojaeian Zanjani on 15/03/26.
//

import Foundation
import PDFKit

class PDFProcessor {
    
    /// Extract text from a PDF file
    static func extractText(from url: URL) throws -> String {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw PDFProcessorError.failedToLoadPDF
        }
        
        var extractedText = ""
        
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            guard let pageText = page.string else { continue }
            extractedText += pageText + "\n\n"
        }
        
        guard !extractedText.isEmpty else {
            throw PDFProcessorError.noTextFound
        }
        
        return extractedText
    }
    
    /// Split text into chunks of approximately chunkSize words
    static func chunkText(_ text: String, chunkSize: Int = 500, overlap: Int = 50) -> [String] {
        let words = text.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return [] }
        
        var chunks: [String] = []
        var currentIndex = 0
        
        while currentIndex < words.count {
            let endIndex = min(currentIndex + chunkSize, words.count)
            let chunk = words[currentIndex..<endIndex].joined(separator: " ")
            chunks.append(chunk)
            
            // Move forward with overlap
            currentIndex += (chunkSize - overlap)
            
            // Ensure we don't get stuck in infinite loop
            if chunkSize <= overlap {
                currentIndex += 1
            }
        }
        
        return chunks
    }
    
    /// Extract text from a plain text file
    static func extractTextFromFile(url: URL) throws -> String {
        do {
            // Check if file exists and is readable
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw PDFProcessorError.fileNotFound
            }
            
            // Try to read with UTF-8 encoding first
            if let content = try? String(contentsOf: url, encoding: .utf8) {
                guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw PDFProcessorError.noTextFound
                }
                return content
            }
            
            // Fallback to other encodings
            let encodings: [String.Encoding] = [.utf16, .ascii, .isoLatin1]
            
            for encoding in encodings {
                if let content = try? String(contentsOf: url, encoding: encoding) {
                    guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        continue
                    }
                    return content
                }
            }
            
            throw PDFProcessorError.unreadableFile
            
        } catch let error as PDFProcessorError {
            throw error
        } catch {
            throw PDFProcessorError.fileAccessDenied
        }
    }
}

enum PDFProcessorError: Error, LocalizedError {
    case failedToLoadPDF
    case noTextFound
    case fileNotFound
    case fileAccessDenied
    case unreadableFile
    
    var errorDescription: String? {
        switch self {
        case .failedToLoadPDF:
            return "Failed to load PDF file"
        case .noTextFound:
            return "No text content found in file"
        case .fileNotFound:
            return "File not found"
        case .fileAccessDenied:
            return "Permission denied. Please try selecting the file again."
        case .unreadableFile:
            return "Unable to read file content. The file may be corrupted or in an unsupported format."
        }
    }
}
