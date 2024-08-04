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
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .floatingPanel(isPresented: $appState.isPanelPresented, content: {
                    FloatingPanelView()
                })
        }
        .modelContainer(for: Project.self)
        
        Settings {
            ShortcutSettingsView()
        }
    }
}
