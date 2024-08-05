//
//  AppState.swift
//  TeamLongHair
//
//  Created by Damin on 7/31/24.
//

import SwiftUI

@Observable
final class AppState {
    
    static let shared = AppState()
    // 초기값을 디폴트 단축키로 설정
    private var keyShortcut: KeyShortcut = KeyShortcut(modifierFlags: [.command, .shift], keyCode: 5)
    var isPanelPresented: Bool = false
    
    private init() {
        loadShortcutgKeys()
    }
    
    func loadShortcutgKeys() {
        let userDefaults = UserDefaults.standard

        guard let savedKeyCode = userDefaults.object(forKey: "shortcutKeyCode") as? Int else {
            userDefaults.set(keyShortcut.keyCode, forKey: "shortcutKeyCode")
            return
        }
        
        guard let savedModifierFlagsValue = userDefaults.object(forKey: "shortcutModifierFlags") as? UInt else {
            userDefaults.set(keyShortcut.modifierFlags.rawValue, forKey: "shortcutModifierFlags")
            return
        }

       keyShortcut = KeyShortcut(modifierFlags: NSEvent.ModifierFlags(rawValue: savedModifierFlagsValue), keyCode: savedKeyCode)
        
    }
    
    func checkLocalEventIsKeyShortcut(event: NSEvent) -> NSEvent {
        loadShortcutgKeys()
        
        if event.keyCode == 53 {
            isPanelPresented = false
            return event
        }
        
        if event.keyCode == keyShortcut.keyCode && event.modifierFlags.intersection(.deviceIndependentFlagsMask) == keyShortcut.modifierFlags.intersection(.deviceIndependentFlagsMask) {
            debugPrint("Custom Local shortcut triggered")
            isPanelPresented.toggle()
            return event
        }
        
        return event
    }
    
    func checkGlobalEventIsKeyShortcut(event: NSEvent) {
        loadShortcutgKeys()
        
        if event.keyCode == keyShortcut.keyCode && event.modifierFlags.intersection(.deviceIndependentFlagsMask) == keyShortcut.modifierFlags.intersection(.deviceIndependentFlagsMask) {
            debugPrint("Custom Global shortcut triggered")
            isPanelPresented.toggle()
        }
    }
}
