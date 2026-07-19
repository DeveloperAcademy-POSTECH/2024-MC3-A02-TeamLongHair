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
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 전역 단축키는 Carbon 핫키로 등록한다(권한 불필요, 브라우저로 안 샘).
        HotKeyCenter.shared.onHotKey = { AppState.shared.handleHotKey() }
        let s = appState.currentShortcut
        let registered = HotKeyCenter.shared.register(
            keyCode: UInt32(s.keyCode),
            carbonModifiers: HotKeyModifiers.carbonMask(cocoaRawValue: s.modifierFlags.rawValue))
        if !registered {
            debugPrint("HotKeyCenter: failed to register launch shortcut (\(s.description))")
        }

        startMonitoringKeys()   // 패널 내부 키용 로컬 모니터만 남는다.
        statusBarController = StatusBarController()
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopMonitoringKeys()
        HotKeyCenter.shared.unregister()
    }

    func startMonitoringKeys() {
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            self.appState.checkLocalEventIsKeyShortcut(event: event)
        }
    }

    func stopMonitoringKeys() {
        if let localKeyMonitor = self.localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }
    }
}
