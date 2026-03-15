//
//  DocumentLibraryViewModel.swift
//  LLMsApp
//
//  Created by Omid Shojaeian Zanjani on 15/03/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DocumentLibraryViewModel: ObservableObject {
    @Published var documents: [DocumentModel] = []
    @Published var isImporting: Bool = false
    @Published var importProgress: String = ""
    @Published var lastError: Error?
    
    private let databaseManager: VectorDatabaseManager
    
    init(databaseManager: VectorDatabaseManager) {
        self.databaseManager = databaseManager
        loadDocuments()
    }
    
    // MARK: - Document Operations
    
    func loadDocuments() {
        documents = databaseManager.documents
    }
    
    func deleteDocument(at offsets: IndexSet) {
        for index in offsets {
            let document = documents[index]
            databaseManager.removeDocument(id: document.id)
        }
        loadDocuments()
    }
    
    func deleteDocument(id: UUID) {
        databaseManager.removeDocument(id: id)
        loadDocuments()
    }
    
    // MARK: - Import Operations
    
    func importPDF(url: URL) async {
        isImporting = true
        importProgress = "Processing PDF..."
        lastError = nil
        
        do {
            let document = try await databaseManager.importPDF(url: url)
            databaseManager.addDocument(document)
            loadDocuments()
            importProgress = "Import successful!"
            
            // Clear progress after delay
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            importProgress = ""
        } catch {
            lastError = error
            importProgress = ""
        }
        
        isImporting = false
    }
    
    func importTextFile(url: URL) async {
        isImporting = true
        importProgress = "Processing text file..."
        lastError = nil
        
        do {
            let document = try await databaseManager.importTextFile(url: url)
            databaseManager.addDocument(document)
            loadDocuments()
            importProgress = "Import successful!"
            
            // Clear progress after delay
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            importProgress = ""
        } catch {
            lastError = error
            importProgress = ""
        }
        
        isImporting = false
    }
}
