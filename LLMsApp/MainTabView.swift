//
//  MainTabView.swift
//  LLMsApp
//
//  Created by Omid Shojaeian Zanjani on 15/03/26.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var settings = ModelSettings()
    @StateObject private var viewModel: ModelAdapterViewModel
    
    init() {
        let settings = ModelSettings()
        let engine = MockLLMEngine(settings: settings)
        _viewModel = StateObject(wrappedValue: ModelAdapterViewModel(engine: engine))
        _settings = StateObject(wrappedValue: settings)
    }
    
    var body: some View {
        TabView {
            NavigationView {
                ChatView(viewModel: viewModel, settings: settings)
                    .navigationTitle("Chat")
            }
            .tabItem {
                Label("Chat", systemImage: "message.fill")
            }
            
            NavigationView {
                SettingsView(settings: settings)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
    }
}

#Preview {
    MainTabView()
}
