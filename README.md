# LLMsApp - Local LLM Runner for iOS/macOS

A native Swift application for running Large Language Models (LLMs) locally on iOS and macOS devices using llama.cpp through the SwiftLlama wrapper.

## Table of Contents
- [Overview](#overview)
- [Problem Statement](#problem-statement)
- [Solution](#solution)
- [Features](#features)
- [Architecture](#architecture)
- [Design Patterns](#design-patterns)
- [Libraries & Dependencies](#libraries--dependencies)
- [Project Structure](#project-structure)
- [Memory Optimization](#memory-optimization)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Technical Details](#technical-details)
- [Future Enhancements](#future-enhancements)

---

## Overview

LLMsApp is a SwiftUI-based application that enables users to run quantized LLM models (in GGUF format) directly on Apple devices without requiring cloud connectivity or external APIs. The app provides a user-friendly interface for model configuration, real-time text generation, and comprehensive parameter tuning.

## Problem Statement

### Challenges Addressed:
1. **Privacy Concerns**: Using cloud-based LLM APIs exposes user data to third parties
2. **Network Dependency**: Cloud solutions require stable internet connectivity
3. **Cost**: API usage can become expensive with frequent use
4. **Latency**: Network round-trips add significant delays to response generation
5. **Resource Management**: Running LLMs on mobile devices requires careful memory and CPU management
6. **Complexity**: Integrating low-level C/C++ libraries (llama.cpp) with Swift requires careful bridging

## Solution

LLMsApp solves these challenges by:

1. **Local Execution**: All model inference runs entirely on-device using llama.cpp
2. **SwiftUI Integration**: Modern, declarative UI that's native to Apple platforms
3. **Memory Optimization**: Configurable parameters to balance performance and memory usage
4. **Real-time Streaming**: Token-by-token generation with live UI updates
5. **Flexible Configuration**: Comprehensive settings for model behavior tuning
6. **Clean Architecture**: MVVM pattern with protocol-oriented design for maintainability

---

## Features

### Core Functionality
- ✅ Load and run GGUF quantized models locally
- ✅ Real-time streaming text generation
- ✅ Model hot-swapping (load/unload different models)
- ✅ Generation cancellation support
- ✅ Error handling and user feedback

### Vector Database & RAG
- ✅ Import PDF and text documents
- ✅ Automatic text chunking and embedding generation
- ✅ Vector similarity search for document chunks
- ✅ RAG (Retrieval-Augmented Generation) chat per document
- ✅ Document library with navigation to individual chats
- ✅ Source attribution showing which chunks were used

### Configuration Options
- **Model Parameters**:
  - Batch size (16-256)
  - Context window size (128-2048 tokens)
  - GPU acceleration toggle (Metal support)

- **Sampling Parameters**:
  - Temperature (0.0-2.0)
  - Top-P nucleus sampling (0.0-1.0)
  - Top-K sampling (disabled/10/20/40/80)
  - Random seed for reproducibility
  - Minimum token keep threshold

- **Repetition Control**:
  - Repetition penalty (1.0-2.0)
  - Frequency penalty (0.0-2.0)
  - Presence penalty (0.0-2.0)
  - Penalty window size (0-512 tokens)

- **System Prompts**:
  - Optional system message injection
  - Customizable conversation context

### User Interface
- **Tab-based Navigation**:
  - Chat tab for interaction
  - Settings tab for configuration
- **Live Status Updates**:
  - Loading indicators
  - Generation progress
  - Current settings display
- **Error Display**: Clear error messages with localized descriptions

---

## Architecture

### Overall Architecture: MVVM (Model-View-ViewModel)

```
┌─────────────────────────────────────────────────────────────┐
│                         SwiftUI Views                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  ChatView    │  │ SettingsView │  │ MainTabView  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└────────────┬────────────────┬────────────────────────────────┘
             │                │
             │ @ObservedObject│
             ▼                ▼
┌─────────────────────────────────────────────────────────────┐
│                        ViewModels                            │
│  ┌────────────────────────────────────────────────────────┐ │
│  │       ModelAdapterViewModel (ObservableObject)         │ │
│  │  - @Published isLoading, isGenerating, generatedText  │ │
│  │  - loadModel(at:), generate(prompt:), cancel()        │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │         ModelSettings (ObservableObject)               │ │
│  │  - @Published temperature, batchSize, topP, etc.       │ │
│  │  - resetToDefaults()                                   │ │
│  └────────────────────────────────────────────────────────┘ │
└────────────┬──────────────────────────────────────────────────┘
             │ Protocol
             │ Abstraction
             ▼
┌─────────────────────────────────────────────────────────────┐
│                      Engine Layer                            │
│  ┌────────────────────────────────────────────────────────┐ │
│  │            LLMEngine Protocol                          │ │
│  │  - loadModel(from:)                                    │ │
│  │  - unloadModel()                                       │ │
│  │  - generate(prompt:, tokenHandler:)                    │ │
│  │  - cancelGeneration()                                  │ │
│  └────────────────────────────────────────────────────────┘ │
│                          ▲                                   │
│                          │ implements                        │
│  ┌────────────────────────────────────────────────────────┐ │
│  │          MockLLMEngine (LLMEngine)                     │ │
│  │  - Wraps LlamaService from SwiftLlama                  │ │
│  │  - Applies ModelSettings dynamically                   │ │
│  │  - Handles async/await and streaming                   │ │
│  └────────────────────────────────────────────────────────┘ │
└────────────┬──────────────────────────────────────────────────┘
             │ uses
             ▼
┌─────────────────────────────────────────────────────────────┐
│                   SwiftLlama Library                         │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  LlamaService (Actor)                                  │ │
│  │  - streamCompletion(of:samplingConfig:)                │ │
│  │  - LlamaConfig, LlamaSamplingConfig                    │ │
│  │  - LlamaRepetitionPenaltyConfig                        │ │
│  └────────────────────────────────────────────────────────┘ │
└────────────┬──────────────────────────────────────────────────┘
             │ wraps
             ▼
┌─────────────────────────────────────────────────────────────┐
│                      llama.cpp (C++)                         │
│  - Model loading and inference                               │
│  - Token generation                                          │
│  - Memory management                                         │
│  - Platform-specific optimizations (Metal/CPU)              │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

**Model Loading:**
```
User taps "Load" → ChatView
  → ModelAdapterViewModel.loadModelFromBundle(named:)
    → LLMEngine.loadModel(from: path)
      → MockLLMEngine creates LlamaService with ModelSettings
        → SwiftLlama.LlamaService initializes
          → llama.cpp loads GGUF model into memory
```

**Text Generation:**
```
User enters prompt and taps "Generate" → ChatView
  → ModelAdapterViewModel.generate(prompt:)
    → Task { engine.generate(prompt:, tokenHandler:) }
      → MockLLMEngine.generate()
        → Builds messages (with optional system prompt)
        → Creates LlamaSamplingConfig from ModelSettings
        → LlamaService.streamCompletion() → AsyncThrowingStream
          → For each token:
            → tokenHandler(token) called on background thread
              → Task { @MainActor: append to generatedText }
                → SwiftUI updates UI automatically
```

---

## Design Patterns

### 1. **Protocol-Oriented Programming**
- **LLMEngine Protocol**: Defines interface for any LLM backend
- **Benefits**:
  - Testability: Easy to create mock implementations
  - Flexibility: Can swap backends (llama.cpp, other engines)
  - Dependency Inversion: ViewModel depends on protocol, not concrete implementation

```swift
public protocol LLMEngine {
    func loadModel(from path: String) async throws
    func unloadModel() async throws
    func generate(prompt: String, tokenHandler: @escaping (_ token: String) -> Bool) async throws
    func cancelGeneration()
}
```

### 2. **MVVM (Model-View-ViewModel)**
- **Views**: SwiftUI views (ChatView, SettingsView)
- **ViewModels**: `ModelAdapterViewModel`, `ModelSettings`
- **Model/Engine**: `MockLLMEngine` + SwiftLlama library
- **Benefits**:
  - Separation of concerns
  - Testable business logic
  - Reactive UI updates via `@Published` properties

### 3. **Dependency Injection**
- Engine is injected into ViewModel at initialization
- Settings are shared between View and Engine
- **Benefits**:
  - Loose coupling
  - Easy testing with mock dependencies
  - Runtime configuration flexibility

```swift
init(engine: LLMEngine) {
    self.engine = engine
}
```

### 4. **Observer Pattern**
- `ObservableObject` + `@Published` properties
- SwiftUI automatically observes changes and updates UI
- **Example**: When `generatedText` changes, ScrollView updates in real-time

### 5. **Strategy Pattern**
- Different sampling strategies configurable via `ModelSettings`
- Settings can be changed at runtime without recompiling

### 6. **Adapter Pattern**
- `MockLLMEngine` adapts SwiftLlama's API to our `LLMEngine` protocol
- Bridges async/await with callback-based token handling

### 7. **Command Pattern**
- User actions (Load, Generate, Cancel) are encapsulated as async methods
- Supports undo/cancel operations

---

## Libraries & Dependencies

### Primary Dependencies

#### 1. **SwiftLlama** (v1.2.0)
- **Purpose**: Swift wrapper for llama.cpp
- **Repository**: [pgorzelany/swift-llama-cpp](https://github.com/pgorzelany/swift-llama-cpp)
- **What it provides**:
  - High-level Swift API for llama.cpp
  - Actor-based `LlamaService` for thread safety
  - Streaming token generation via `AsyncThrowingStream`
  - Configuration types: `LlamaConfig`, `LlamaSamplingConfig`, `LlamaRepetitionPenaltyConfig`
- **Integration**: Swift Package Manager

#### 2. **llama.cpp** (Embedded in SwiftLlama)
- **Purpose**: Core LLM inference engine (C++)
- **What it provides**:
  - GGUF model format support
  - Quantization support (Q4, Q5, Q8, etc.)
  - CPU and Metal (GPU) acceleration
  - Memory-efficient inference
  - Cross-platform compatibility

### Native Apple Frameworks

#### 3. **SwiftUI**
- **Purpose**: Modern declarative UI framework
- **Used for**:
  - All user interface components
  - Reactive data binding
  - Navigation and tab views

#### 4. **Combine**
- **Purpose**: Reactive programming framework
- **Used for**:
  - `ObservableObject` protocol
  - `@Published` property wrapper
  - Automatic UI updates

#### 5. **Foundation**
- **Purpose**: Core utilities and types
- **Used for**:
  - File system operations
  - URL handling
  - String manipulation
  - Task/async-await support

---

## Project Structure

```
LLMsApp/
├── LLMsApp/
│   ├── ContentView.swift           # Root view (shows MainTabView)
│   ├── MainTabView.swift           # Tab navigation (Chat/Documents/Settings)
│   ├── ChatView.swift              # Main chat interface
│   ├── SettingsView.swift          # Configuration UI
│   ├── ModelAdapterViewModel.swift # Core ViewModel + LLMEngine protocol
│   ├── ModelSettings.swift         # Observable settings store
│   ├── LLMsAppApp.swift           # App entry point
│   ├── Assets.xcassets/           # Images and colors
│   ├── VectorDatabase/            # Vector DB & RAG implementation
│   │   ├── Models/
│   │   │   └── DocumentModel.swift        # Document and chunk data models
│   │   ├── Services/
│   │   │   ├── VectorDatabaseManager.swift # Document storage and search
│   │   │   ├── PDFProcessor.swift          # PDF text extraction and chunking
│   │   │   └── EmbeddingGenerator.swift    # Vector embedding generation
│   │   ├── ViewModels/
│   │   │   ├── DocumentLibraryViewModel.swift # Document list management
│   │   │   └── DocumentChatViewModel.swift    # RAG chat implementation
│   │   └── Views/
│   │       ├── DocumentLibraryView.swift   # Document list UI
│   │       └── DocumentChatView.swift      # Document chat UI
│   └── Models_llms/               # Local model storage (not in git)
│       └── *.gguf                 # GGUF model files
├── LLMsApp.xcodeproj/             # Xcode project
├── .gitignore                     # Git ignore (excludes *.gguf)
└── README.md                      # This file
```

### Key Files Explained

#### `ModelAdapterViewModel.swift`
- **LLMEngine Protocol**: Abstraction for any LLM backend
- **ModelAdapterViewModel**: Main ViewModel
  - Manages model lifecycle (load/unload)
  - Handles generation and cancellation
  - Publishes state to UI (`isLoading`, `isGenerating`, `generatedText`)
  - Bridges async engine calls to SwiftUI's MainActor

#### `ModelSettings.swift`
- `ObservableObject` that holds all configurable parameters
- Shared between ChatView (display) and Engine (usage)
- Provides `resetToDefaults()` method

#### `ChatView.swift`
- Main interaction interface
- Model load/unload controls
- Text input and generation buttons
- Real-time response display
- Current settings summary

#### `SettingsView.swift`
- Comprehensive configuration UI
- Sliders for continuous parameters (temperature, penalties)
- Toggles for boolean options (GPU, repetition penalty)
- Pickers for discrete choices (Top-K values)
- Text editor for system prompt

#### `ContentView.swift`
- Contains `MockLLMEngine` implementation
- Adapts SwiftLlama to LLMEngine protocol
- Applies ModelSettings to generation requests

---

## Memory Optimization

### Problem: Large Models Cause Memory Pressure

GGUF models can be 1-10GB+ in size. When loaded into memory:
- **Model weights**: 2-4GB for quantized models
- **Context buffer**: Scales with `maxTokenCount`
- **KV cache**: Stores attention keys/values
- **Batch buffers**: Temporary processing memory

### Solutions Implemented

#### 1. **Configurable Context Window**
- Default: 256 tokens (minimum for basic chat)
- Range: 128-2048 tokens
- **Impact**: 256 tokens uses ~10x less memory than 2048

#### 2. **Reduced Batch Size**
- Default: 64 (vs. typical 512)
- Range: 16-256
- **Impact**: Smaller batches = less temporary memory

#### 3. **CPU-First Approach**
- Default: `useGPU = false`
- GPU can allocate large contiguous memory blocks
- CPU mode uses paged memory, better for constrained devices

#### 4. **Explicit Cleanup**
- `unloadModel()` explicitly releases LlamaService
- Added `Task.sleep()` to allow OS memory reclamation
- Cancels ongoing generation before unload

#### 5. **Quantized Models**
- Use Q4_K_S or Q4_K_M quantization
- 4-bit quantization reduces model size by ~4x vs. full precision
- Example: 7B model at Q4 ≈ 4GB vs. 16GB at FP16

### Memory Usage Guidelines

| Model Size | Quantization | Recommended Max Tokens | Device |
|------------|--------------|------------------------|--------|
| 1B params  | Q4_K_S       | 512-1024              | iPhone/iPad |
| 3B params  | Q4_K_M       | 256-512               | iPhone/iPad |
| 7B params  | Q4_K_S       | 128-256               | iPad Pro/Mac |
| 13B params | Q4_K_M       | 128                   | Mac only |

---

## Installation

### Prerequisites
- Xcode 15.0+
- iOS 16.0+ / macOS 13.0+
- Swift 5.9+

### Steps

1. **Clone the repository**
```bash
git clone <repository-url>
cd LLMsApp
```

2. **Open in Xcode**
```bash
open LLMsApp.xcodeproj
```

3. **Install dependencies**
- Xcode will automatically resolve Swift Package Manager dependencies
- SwiftLlama will be downloaded and linked

4. **Add a GGUF model**
- Download a quantized GGUF model (e.g., from Hugging Face)
- Recommended: Start with a small model (1-3B parameters, Q4 quantization)
- Place the `.gguf` file in `LLMsApp/Models_llms/`
- Example sources:
  - [TheBloke's Hugging Face](https://huggingface.co/TheBloke)
  - [GGUF models collection](https://huggingface.co/models?search=gguf)

5. **Build and Run**
- Select target device (Simulator or physical device)
- Press Cmd+R or click Run
- **Note**: Physical device recommended for better performance

---

## Usage

### Loading a Model

1. Launch the app
2. Go to **Chat** tab
3. Enter model name in "Model name" field (without `.gguf` extension)
   - Example: `gemma-3-4b-it-Q4_K_S`
4. Tap **Load** button
5. Wait for "Loading model..." indicator to complete

### Generating Text

1. Ensure model is loaded
2. Enter your prompt in "Your message" field
3. Tap **Generate** button
4. Watch as tokens appear in real-time in the response area
5. Tap **Stop** to cancel generation at any time

### Configuring Settings

1. Go to **Settings** tab
2. Adjust parameters as needed:
   - **Model Configuration**: Batch size, max tokens, GPU toggle
   - **Generation Settings**: Temperature, Top-P, Top-K, seed
   - **Repetition Penalty**: Enable and tune penalties
   - **System Prompt**: Add context to every conversation
3. Changes apply immediately to next generation
4. Tap **Reset to Defaults** to restore default values

### Unloading a Model

1. Tap **Unload** button in Chat tab
2. This frees memory for loading a different model
3. Useful when switching between models

### Using Vector Database (RAG)

1. **Import Documents**:
   - Go to **Documents** tab
   - Tap **Import PDF** or **Import Text**
   - Select files from your device
   - App extracts text, creates chunks, and generates embeddings

2. **Chat with Documents**:
   - Tap any document in the library
   - Ask questions about the document content
   - App searches relevant chunks and provides context-aware answers
   - See source attribution showing which chunks were used

3. **Document Management**:
   - Swipe to delete documents
   - View chunk count and import date
   - Navigate between different document chats

---

## Configuration

### Default Settings

```swift
// Model Configuration
batchSize: 64
maxTokenCount: 256
useGPU: false

// Sampling
temperature: 0.8
seed: 42
topP: 0.95
topK: nil (disabled)
minKeep: 1

// Repetition Penalty
enableRepetitionPenalty: true
repetitionPenalty: 1.1
frequencyPenalty: 0.0
presencePenalty: 0.0
penaltyLastN: 64

// System Prompt
useSystemPrompt: false
systemPrompt: "You are a helpful assistant."
```

### Recommended Settings by Use Case

#### Creative Writing
```
temperature: 1.2-1.5
topP: 0.9
repetitionPenalty: 1.2
```

#### Factual Q&A
```
temperature: 0.2-0.5
topP: 0.95
repetitionPenalty: 1.0
```

#### Code Generation
```
temperature: 0.1
topP: 0.95
topK: 40
repetitionPenalty: 1.0
```

#### Conversational Chat
```
temperature: 0.7-0.9
topP: 0.95
repetitionPenalty: 1.1
presencePenalty: 0.6
```

---

## Technical Details

### Threading Model

- **Main Thread (MainActor)**:
  - All UI updates
  - ViewModel state changes
  - User interactions

- **Background Thread**:
  - Model loading
  - Token generation
  - File I/O

- **Synchronization**:
  - `Task { @MainActor }` for UI updates from background
  - `async/await` for structured concurrency
  - `LlamaService` is an `actor` for thread safety

### Token Streaming Implementation

```swift
let stream = try await service.streamCompletion(of: messages, samplingConfig: config)

for try await token in stream {
    let shouldContinue = tokenHandler(token)
    if !shouldContinue || Task.isCancelled {
        break
    }
}
```

- `AsyncThrowingStream` provides backpressure
- Token handler called for each generated token
- Can cancel mid-generation by returning `false` or checking `Task.isCancelled`

### Error Handling

```swift
public enum ModelAdapterError: Error, LocalizedError {
    case modelNotLoaded
    case engineError(String)
}
```

- All async operations wrapped in `do-catch`
- Errors published to UI via `lastError` property
- User sees localized error descriptions

---

## Future Enhancements

### Planned Features
- [ ] **Multi-model support**: Load multiple models simultaneously
- [ ] **Conversation history**: Save and load chat sessions
- [ ] **Model download**: In-app model browser and downloader
- [ ] **Performance metrics**: Display tokens/second, memory usage
- [ ] **Custom chat templates**: Support different model instruction formats
- [ ] **Image input**: Support for vision models (LLaVA, etc.)
- [ ] **Voice input/output**: Speech-to-text and TTS integration
- [ ] **Export conversations**: Share as text/markdown/PDF
- [ ] **Dark mode themes**: Additional UI customization
- [ ] **Shortcuts integration**: Siri shortcuts for quick generation

### Technical Improvements
- [ ] **Unit tests**: Add comprehensive test coverage
- [ ] **UI tests**: Automated UI testing
- [ ] **Performance profiling**: Optimize memory and CPU usage
- [ ] **Background generation**: Continue generation when app backgrounds
- [ ] **Model validation**: Check model compatibility before loading
- [ ] **Better error messages**: More specific error descriptions
- [ ] **Settings persistence**: Save user preferences
- [ ] **Model presets**: Quick-switch configuration profiles

---

## License

[Specify your license here]

## Contributing

[Add contribution guidelines if open source]

## Acknowledgments

- **llama.cpp**: Georgi Gerganov and contributors for the amazing inference engine
- **SwiftLlama**: Piotr Gorzelany for the Swift wrapper
- **Apple**: For SwiftUI and modern Swift concurrency features

---

## Contact

My email: omidshz100@gmail.com
---

**Built with ❤️ using Swift and SwiftUI**
