//
//  AppearanceMode.swift
//  TeamLongHair
//
//  앱 화면 모드(시스템/라이트/다크) 선택. UserDefaults 키 "appearanceMode"에 저장.
//

import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "시스템"
        case .light: return "라이트"
        case .dark: return "다크"
        }
    }

    /// `.preferredColorScheme`에 넘길 값. 시스템 모드는 nil(시스템 설정을 따름).
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
