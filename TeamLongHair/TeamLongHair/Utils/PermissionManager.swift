//
//  PermissionManager.swift
//  TeamLongHair
//
//  앱이 필요로 하는 시스템 권한(손쉬운 사용·자동화)의 상태 확인과 설정 이동을 담당.
//

import AppKit

@Observable
final class PermissionManager {
    static let shared = PermissionManager()
    private init() {}

    /// 손쉬운 사용(Accessibility) 허용 여부. 전역 단축키 모니터링에 필요.
    var accessibilityGranted: Bool = AXIsProcessTrusted()

    /// 현재 시스템 상태로 다시 확인한다(설정에서 돌아왔을 때 등).
    func refresh() {
        accessibilityGranted = AXIsProcessTrusted()
    }

    /// 손쉬운 사용 허용을 요청하는 시스템 프롬프트를 띄운다.
    func promptAccessibility() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    /// 시스템 설정의 손쉬운 사용 창을 연다.
    func openAccessibilitySettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    /// 시스템 설정의 자동화 창을 연다.
    func openAutomationSettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")
    }

    private func open(_ string: String) {
        if let url = URL(string: string) {
            NSWorkspace.shared.open(url)
        }
    }
}
