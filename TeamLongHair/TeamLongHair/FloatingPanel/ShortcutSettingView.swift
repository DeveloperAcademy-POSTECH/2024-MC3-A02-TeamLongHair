//
//  ShortcutSettingView.swift
//  TeamLongHair
//
//  Created by Damin on 7/31/24.
//

import SwiftUI

struct ShortcutSettingsView: View {
    @State private var shortcut: KeyShortcut?
    @State private var localKeyMonitor: Any?
    
    init() {
        // UserDefaults에서 저장된 값을 불러와서 초기화
        let keyCode = UserDefaults.standard.integer(forKey: "shortcutKeyCode")
        let modifierFlagsValue = UserDefaults.standard.integer(forKey: "shortcutModifierFlags")
        let modifierFlags = NSEvent.ModifierFlags(rawValue: UInt(modifierFlagsValue))
        
        // shortcut State 변수의 초기값 설정
        if keyCode != 0 || modifierFlagsValue != 0 {
            _shortcut = State(initialValue: KeyShortcut(modifierFlags: modifierFlags, keyCode: keyCode))
        } else {
            _shortcut = State(initialValue: nil)
        }
    }

    var body: some View {
        VStack {
            Text("Press your desired shortcut")
            Text(shortcut?.description ?? "No shortcut set")
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .onTapGesture {
                    startListeningForShortcut()
                }
            Button("Save Shortcut") {
                saveShortcut()
            }
            .disabled(shortcut == nil)
        }
        .padding()
        .onDisappear {
            stopMonitoringKeys()
        }
    }

    func startListeningForShortcut() {
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            shortcut = .init(modifierFlags: event.modifierFlags, keyCode: Int(event.keyCode))
            return event
        }
    }

    func saveShortcut() {
        if let shortcut = shortcut {
            UserDefaults.standard.set(shortcut.keyCode, forKey: "shortcutKeyCode")
            UserDefaults.standard.set(shortcut.modifierFlags.rawValue, forKey: "shortcutModifierFlags")
        }
        stopMonitoringKeys()
    }
    
    func stopMonitoringKeys() {
        if let localKeyMonitor = self.localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }
    }
}
