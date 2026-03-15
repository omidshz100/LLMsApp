//
//  DocumentChatView.swift
//  LLMsApp
//
//  Created by Omid Shojaeian Zanjani on 15/03/26.
//

import SwiftUI

struct DocumentChatView: View {
    @StateObject private var viewModel: DocumentChatViewModel
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    let document: DocumentModel
    
    init(document: DocumentModel, databaseManager: VectorDatabaseManager, llmViewModel: ModelAdapterViewModel) {
        self.document = document
        _viewModel = StateObject(wrappedValue: DocumentChatViewModel(
            document: document,
            databaseManager: databaseManager,
            llmViewModel: llmViewModel
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Document Info Header
            documentInfoHeader
            
            Divider()
            
            // Chat Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            DocumentMessageBubble(message: message, document: document)
                                .id(message.id)
                        }
                        
                        // Loading indicator
                        if viewModel.isGenerating {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Searching document and generating answer...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            .id("loading")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.isGenerating) { generating in
                    if generating {
                        scrollToBottom(proxy: proxy)
                    }
                }
                .onChange(of: viewModel.currentResponse) { _ in
                    scrollToBottom(proxy: proxy)
                }
            }
            
            // Error Display
            if let error = viewModel.lastError {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
            }
            
            Divider()
            
            // Input Area
            chatInputArea
        }
        .navigationTitle(document.fileName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {}) {
                        Label("Document Info", systemImage: "info.circle")
                    }
                    Button(role: .destructive, action: { dismiss() }) {
                        Label("Close Chat", systemImage: "xmark")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    // MARK: - Document Info Header
    
    private var documentInfoHeader: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: document.fileType.icon)
                    .foregroundColor(.blue)
                Text(document.fileName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(document.totalChunks) chunks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Chat Input
    
    private var chatInputArea: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Ask about this document...", text: $inputText, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...5)
                .focused($isInputFocused)
                .disabled(viewModel.isGenerating)
            
            if viewModel.isGenerating {
                Button(action: {
                    viewModel.cancelGeneration()
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.red)
                }
            } else {
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(inputText.isEmpty ? .gray : .blue)
                }
                .disabled(inputText.isEmpty)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - Helper Methods
    
    private func sendMessage() {
        let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        viewModel.sendMessage(message)
        inputText = ""
        isInputFocused = false
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                if viewModel.isGenerating {
                    proxy.scrollTo("loading", anchor: .bottom)
                } else if let lastMessage = viewModel.messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }
}

// MARK: - Message Bubble Component

struct DocumentMessageBubble: View {
    let message: DocumentChatMessage
    let document: DocumentModel
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                Text(message.text.isEmpty ? "..." : message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isUser ? Color.blue : Color(UIColor.systemGray5))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(16)
                
                // Show sources for AI messages
                if !message.isUser && !message.sources.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.caption2)
                        Text("Sources: Chunks \(message.sources.map(String.init).joined(separator: ", "))")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser { Spacer() }
        }
    }
}

#Preview {
    NavigationView {
        DocumentChatView(
            document: DocumentModel(
                fileName: "Sample.pdf",
                fileType: .pdf,
                chunks: []
            ),
            databaseManager: VectorDatabaseManager(),
            llmViewModel: ModelAdapterViewModel(engine: MockLLMEngine(settings: ModelSettings()))
        )
    }
}
