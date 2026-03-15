//
//  SettingsView.swift
//  LLMsApp
//
//  Created by Omid Shojaeian Zanjani on 15/03/26.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: ModelSettings
    
    var body: some View {
        Form {
            // MARK: - Model Configuration Section
            Section(header: Text("Model Configuration")) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Batch Size: \(settings.batchSize)")
                        .font(.subheadline)
                    Slider(value: Binding(
                        get: { Double(settings.batchSize) },
                        set: { settings.batchSize = Int($0) }
                    ), in: 16...256, step: 16)
                    Text("Lower values = less memory usage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Max Token Count (Context): \(settings.maxTokenCount)")
                        .font(.subheadline)
                    Slider(value: Binding(
                        get: { Double(settings.maxTokenCount) },
                        set: { settings.maxTokenCount = Int($0) }
                    ), in: 128...2048, step: 128)
                    Text("Context window size")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Toggle("Use GPU", isOn: $settings.useGPU)
                    .help("Enable GPU processing (requires more memory)")
            }
            
            // MARK: - Sampling Configuration Section
            Section(header: Text("Generation Settings")) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Temperature: \(String(format: "%.2f", settings.temperature))")
                        .font(.subheadline)
                    Slider(value: $settings.temperature, in: 0.0...2.0, step: 0.1)
                    Text("0.0 = deterministic, 2.0 = more creative")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Top-P: \(String(format: "%.2f", settings.topP))")
                        .font(.subheadline)
                    Slider(value: $settings.topP, in: 0.0...1.0, step: 0.05)
                    Text("Nucleus sampling")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Top-K:")
                        .font(.subheadline)
                    Spacer()
                    if let topK = settings.topK {
                        Text("\(topK)")
                            .foregroundColor(.secondary)
                    } else {
                        Text("Disabled")
                            .foregroundColor(.secondary)
                    }
                }
                
                Picker("Top-K", selection: Binding(
                    get: { settings.topK ?? -1 },
                    set: { settings.topK = $0 == -1 ? nil : $0 }
                )) {
                    Text("Disabled").tag(Int32(-1))
                    Text("10").tag(Int32(10))
                    Text("20").tag(Int32(20))
                    Text("40").tag(Int32(40))
                    Text("80").tag(Int32(80))
                }
                .pickerStyle(.menu)
                
                Stepper("Min Keep: \(settings.minKeep)",
                       value: $settings.minKeep, in: 1...10)
                    .font(.subheadline)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Seed: \(settings.seed)")
                        .font(.subheadline)
                    HStack {
                        TextField("Seed", value: $settings.seed, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        Button("Random") {
                            settings.seed = UInt32.random(in: 0...UInt32.max)
                        }
                        .buttonStyle(.bordered)
                    }
                    Text("For reproducible results")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // MARK: - Repetition Penalty Section
            Section(header: Text("Repetition Penalty")) {
                Toggle("Enable Repetition Penalty", isOn: $settings.enableRepetitionPenalty)
                
                if settings.enableRepetitionPenalty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Repetition Penalty: \(String(format: "%.2f", settings.repetitionPenalty))")
                            .font(.subheadline)
                        Slider(value: $settings.repetitionPenalty, in: 1.0...2.0, step: 0.05)
                        Text("1.0 = no penalty, higher = less repetition")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Frequency Penalty: \(String(format: "%.2f", settings.frequencyPenalty))")
                            .font(.subheadline)
                        Slider(value: $settings.frequencyPenalty, in: 0.0...2.0, step: 0.1)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Presence Penalty: \(String(format: "%.2f", settings.presencePenalty))")
                            .font(.subheadline)
                        Slider(value: $settings.presencePenalty, in: 0.0...2.0, step: 0.1)
                    }
                    
                    Stepper("Penalty Last N Tokens: \(settings.penaltyLastN)",
                           value: $settings.penaltyLastN, in: 0...512, step: 32)
                        .font(.subheadline)
                }
            }
            
            // MARK: - System Prompt Section
            Section(header: Text("System Prompt")) {
                Toggle("Use System Prompt", isOn: $settings.useSystemPrompt)
                
                if settings.useSystemPrompt {
                    TextEditor(text: $settings.systemPrompt)
                        .frame(minHeight: 100)
                        .border(Color.gray.opacity(0.3), width: 1)
                    Text("This text will be added at the start of every conversation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // MARK: - Actions Section
            Section {
                Button(action: {
                    settings.resetToDefaults()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset to Defaults")
                    }
                    .frame(maxWidth: .infinity)
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationView {
        SettingsView(settings: ModelSettings())
    }
}
