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
    var isArrowKeyToggle: Bool = false
    var arrowKey: ArrowKey = .up
    var shouldSaveDataToggle: Bool = false

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
        
        if event.keyCode == KeyShortcut.esc {
            isPanelPresented = false
            return event
        }
        
        if event.keyCode == keyShortcut.keyCode && event.modifierFlags.intersection(.deviceIndependentFlagsMask) == keyShortcut.modifierFlags.intersection(.deviceIndependentFlagsMask) {
            debugPrint("Custom Local shortcut triggered")
            isPanelPresented.toggle()
            return event
        }
        
        if isPanelPresented && isArrowKey(Int(event.keyCode)) {
            for arrow in ArrowKey.allCases {
                if arrow.key == event.keyCode {
                    arrowKey = arrow
                    break
                }
            }
            isArrowKeyToggle.toggle()
        }
        
        if isPanelPresented && event.keyCode == KeyShortcut.enter {
            shouldSaveDataToggle.toggle()
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
    
    func isArrowKey(_ keyCode: Int) -> Bool {
        return ArrowKey.allCases.contains(where: { $0.key == keyCode })
    }
}
