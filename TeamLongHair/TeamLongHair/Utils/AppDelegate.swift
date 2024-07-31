//
//  AppDelegate.swift
//  TeamLongHair
//
//  Created by Damin on 7/31/24.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    
    private let appState = AppState.shared
    private var localKeyMonitor: Any?
    private var globalKeyMonitor: Any?
    // 디폴트 단축키 정보
    private let defaultKeyCode: Int = 5 // G 키
    private let defaultModifierFlags: NSEvent.ModifierFlags = [.command, .shift]

    func applicationDidFinishLaunching(_ notification: Notification) {
        requestAccessibilityPermissions()
        loadAndStartMonitoringKeys()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        stopMonitoringKeys()
    }
    
    func loadAndStartMonitoringKeys() {
        let userDefaults = UserDefaults.standard

        // 기본값을 UserDefaults에 저장
        guard let savedKeyCode = userDefaults.object(forKey: "shortcutKeyCode") as? Int else {
            userDefaults.set(defaultKeyCode, forKey: "shortcutKeyCode")
            appState.keyCode = defaultKeyCode
            return
        }
        
        guard let savedModifierFlagsValue = userDefaults.object(forKey: "shortcutModifierFlags") as? UInt else {
            userDefaults.set(defaultModifierFlags.rawValue, forKey: "shortcutModifierFlags")
            appState.modifierFlags = defaultModifierFlags
            return
        }

        appState.keyCode = savedKeyCode
        appState.modifierFlags = NSEvent.ModifierFlags(rawValue: savedModifierFlagsValue)
        
        startMonitoringKeys()
    }
    
    func startMonitoringKeys() {
        // 로컬 키 모니터링
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // ESC 키코드
            if event.keyCode == 53 {
                NotificationCenter.default.post(name: .toggleFloatingPanel, object: nil, userInfo: ["shouldPresent": false])
                return event
            }
            
            if event.keyCode == self.appState.keyCode ?? 0 && event.modifierFlags.intersection(.deviceIndependentFlagsMask) == self.appState.modifierFlags?.intersection(.deviceIndependentFlagsMask) ?? [] {
                debugPrint("Custom Local shortcut triggered")
                NotificationCenter.default.post(name: .toggleFloatingPanel, object: nil)
                return event
            }
            return event
        }
        
        // 글로벌 키 모니터링
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [self] event in
            if event.keyCode == self.appState.keyCode ?? 0 && event.modifierFlags.intersection(.deviceIndependentFlagsMask) == appState.modifierFlags?.intersection(.deviceIndependentFlagsMask) ?? [] {
                debugPrint("Custom Global shortcut triggered")
                NotificationCenter.default.post(name: .toggleFloatingPanel, object: nil, userInfo: ["shouldPresent": true])
            }
        }
    }
    
    func stopMonitoringKeys() {
        if let localKeyMonitor = self.localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }
        
        if let globalKeyMonitor = self.globalKeyMonitor {
            NSEvent.removeMonitor(globalKeyMonitor)
            self.globalKeyMonitor = nil
        }
    }
    
    //TODO: 사용자가 권한 허용 할 수 있도록 설정 연결
    func requestAccessibilityPermissions() {
        let options: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessEnabled {
            print("Accessibility permissions are not enabled. Please enable them in System Preferences.")
        } else {
            print("Accessibility permissions are enabled.")
        }
    }
}
