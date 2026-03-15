//
//  DocumentLibraryView.swift
//  LLMsApp
//
//  Created by Omid Shojaeian Zanjani on 15/03/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentLibraryView: View {
    @StateObject private var viewModel: DocumentLibraryViewModel
    @ObservedObject var llmViewModel: ModelAdapterViewModel
    
    @State private var showingPDFPicker = false
    @State private var showingTextPicker = false
    
    private let databaseManager: VectorDatabaseManager
    
    init(databaseManager: VectorDatabaseManager, llmViewModel: ModelAdapterViewModel) {
        self.databaseManager = databaseManager
        self.llmViewModel = llmViewModel
        _viewModel = StateObject(wrappedValue: DocumentLibraryViewModel(databaseManager: databaseManager))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Import Buttons
            importButtonsSection
            
            Divider()
            
            // Documents List
            if viewModel.documents.isEmpty {
                emptyStateView
            } else {
                documentsListView
            }
        }
        .navigationTitle("Documents")
        .sheet(isPresented: $showingPDFPicker) {
            DocumentPicker(contentTypes: [.pdf]) { url in
                Task {
                    await viewModel.importPDF(url: url)
                }
            }
        }
        .sheet(isPresented: $showingTextPicker) {
            DocumentPicker(contentTypes: [.plainText, .text, .utf8PlainText, .delimitedText]) { url in
                Task {
                    await viewModel.importTextFile(url: url)
                }
            }
        }
    }
    
    // MARK: - Import Section
    
    private var importButtonsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: { showingPDFPicker = true }) {
                    Label("Import PDF", systemImage: "doc.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isImporting)
                
                Button(action: { showingTextPicker = true }) {
                    Label("Import Text", systemImage: "doc.text.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isImporting)
            }
            
            if viewModel.isImporting {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(viewModel.importProgress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !viewModel.importProgress.isEmpty && !viewModel.isImporting {
                Text(viewModel.importProgress)
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            if let error = viewModel.lastError {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Documents Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Import a PDF or text file to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Documents List
    
    private var documentsListView: some View {
        List {
            ForEach(viewModel.documents) { document in
                NavigationLink(destination: DocumentChatView(
                    document: document,
                    databaseManager: databaseManager,
                    llmViewModel: llmViewModel
                )) {
                    DocumentRow(document: document)
                }
            }
            .onDelete(perform: viewModel.deleteDocument)
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Document Row Component

struct DocumentRow: View {
    let document: DocumentModel
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: document.fileType.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(document.fileName)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label("\(document.totalChunks) chunks", systemImage: "square.stack.3d.up")
                    Spacer()
                    Text(document.dateAdded, style: .date)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    let contentTypes: [UTType]
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        
        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("Failed to access security-scoped resource")
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                // Copy file to app's temporary directory to avoid permission issues
                let tempDirectory = FileManager.default.temporaryDirectory
                let fileName = url.lastPathComponent
                let tempURL = tempDirectory.appendingPathComponent(fileName)
                
                // Remove existing file if it exists
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                
                // Copy the file to temp directory
                try FileManager.default.copyItem(at: url, to: tempURL)
                
                // Pass the temp URL to the handler
                onPick(tempURL)
                
            } catch {
                print("Error copying file: \(error.localizedDescription)")
                // Fallback: try to use original URL
                onPick(url)
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // Handle cancellation if needed
        }
    }
}

#Preview {
    NavigationView {
        DocumentLibraryView(
            databaseManager: VectorDatabaseManager(),
            llmViewModel: ModelAdapterViewModel(engine: MockLLMEngine(settings: ModelSettings()))
        )
    }
}
