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

    func applicationDidFinishLaunching(_ notification: Notification) {
        requestAccessibilityPermissions()
        startMonitoringKeys()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        stopMonitoringKeys()
    }
    
    func startMonitoringKeys() {
        // 로컬 키 모니터링
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            self.appState.checkLocalEventIsKeyShortcut(event: event)
        }
        
        // 글로벌 키 모니터링
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            self.appState.checkGlobalEventIsKeyShortcut(event: event)
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
