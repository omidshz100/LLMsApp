//
//  ChatView.swift
//  LLMsApp
//
//  Created by Omid Shojaeian Zanjani on 15/03/26.
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ModelAdapterViewModel
    @ObservedObject var settings: ModelSettings
    @State private var modelName: String = "gemma-3-4b-it-Q4_K_S"
    @State private var prompt: String = "Hello, how are you?"
    
    var body: some View {
        VStack(spacing: 12) {
            // Model Loading Section
            HStack {
                TextField("Model name", text: $modelName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Load") {
                    Task { await viewModel.loadModelFromBundle(named: modelName) }
                }
                .disabled(viewModel.isLoading)
                Button("Unload") {
                    Task { await viewModel.unloadModel() }
                }
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal)
            
            // Prompt Input Section
            HStack {
                TextField("Your message", text: $prompt)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Generate") {
                    viewModel.generate(prompt: prompt)
                }
                .disabled(!viewModel.canGenerate)
                Button("Stop") {
                    viewModel.cancelGeneration()
                }
                .disabled(!viewModel.isGenerating)
            }
            .padding(.horizontal)
            
            // Loading Indicator
            if viewModel.isLoading || viewModel.isGenerating {
                HStack {
                    ProgressView()
                    Text(viewModel.isLoading ? "Loading model..." : "Generating...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Generated Text Display
            ScrollView {
                Text(viewModel.generatedText.isEmpty ? "Response will appear here..." : viewModel.generatedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .foregroundColor(viewModel.generatedText.isEmpty ? .secondary : .primary)
            }
            .background(Color(white: 0.95))
            .cornerRadius(6)
            .frame(minHeight: 200)
            .padding(.horizontal)
            
            // Error Display
            if let err = viewModel.lastError {
                Text(err.localizedDescription)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.horizontal)
            }
            
            // Current Settings Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Settings:")
                    .font(.caption)
                    .fontWeight(.semibold)
                HStack {
                    Text("Temp: \(String(format: "%.1f", settings.temperature))")
                    Spacer()
                    Text("Batch: \(settings.batchSize)")
                    Spacer()
                    Text("Max Token: \(settings.maxTokenCount)")
                    Spacer()
                    Text("GPU: \(settings.useGPU ? "On" : "Off")")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(6)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
    }
}

#Preview {
    NavigationView {
        ChatView(
            viewModel: ModelAdapterViewModel(engine: MockLLMEngine(settings: ModelSettings())),
            settings: ModelSettings()
        )
        .navigationTitle("Chat")
    }
}
