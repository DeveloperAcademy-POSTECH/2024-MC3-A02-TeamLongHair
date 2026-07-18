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
        // 실행 시 권한을 강제로 프롬프트하지 않는다. 첫 실행 온보딩(홈 시트)과
        // 설정 화면의 권한 섹션에서 사용자가 직접 요청하도록 안내한다.
        PermissionManager.shared.refresh()
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
    
}
