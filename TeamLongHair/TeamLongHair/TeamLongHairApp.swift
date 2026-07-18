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
    @AppStorage(AppearanceMode.storageKey) private var appearanceMode: AppearanceMode = .dark

    init() {
        // 첫 실행 시 현재 시스템 외형(라이트/다크)을 기본값으로 심는다.
        AppearanceMode.seedDefaultFromSystemIfNeeded()
    }
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
                        .preferredColorScheme(appearanceMode.colorScheme)
                }
                .modelContainer(modelContainer)
                .preferredColorScheme(appearanceMode.colorScheme)
        }

        Settings {
            ShortcutSettingsView()
                .preferredColorScheme(appearanceMode.colorScheme)
        }
    }
}
