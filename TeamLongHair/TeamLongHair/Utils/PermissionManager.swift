//
//  PermissionManager.swift
//  TeamLongHair
//
//  자동화(Apple Events) 권한 관련 안내/설정 이동을 담당. 전역 단축키가 Carbon 핫키로
//  바뀌어 손쉬운 사용(Accessibility) 권한은 더 이상 필요 없다.
//

import AppKit

@Observable
final class PermissionManager {
    static let shared = PermissionManager()
    private init() {}

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
