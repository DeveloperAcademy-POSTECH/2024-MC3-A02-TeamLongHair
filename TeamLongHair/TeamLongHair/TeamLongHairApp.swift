//
//  TeamLongHairApp.swift
//  TeamLongHair
//
//  Created by Lee Sihyeong on 7/25/24.
//

import SwiftData
import SwiftUI

@main
struct TeamLongHairApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var appState = AppState.shared
    var modelContainer: ModelContainer = {
            let schema = Schema([Project.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }()
    var body: some Scene {
        WindowGroup {
            HomeView()
                .floatingPanel(isPresented: $appState.isPanelPresented) {
                    FloatingPanelView()
                        .environment(appState)
                        .modelContainer(modelContainer)
                }
                .modelContainer(modelContainer)
        }
        
        Settings {
            ShortcutSettingsView()
        }
    }
}
