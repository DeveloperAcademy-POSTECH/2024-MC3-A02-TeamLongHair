//
//  AppearanceMode.swift
//  TeamLongHair
//
//  앱 화면 모드(시스템/라이트/다크) 선택. UserDefaults 키 "appearanceMode"에 저장.
//

import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light: return "라이트"
        case .dark: return "다크"
        }
    }

    var iconName: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    /// 토글 시 반대 모드.
    var toggled: AppearanceMode { self == .dark ? .light : .dark }

    /// `.preferredColorScheme`에 넘길 값.
    var colorScheme: ColorScheme {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }

    static let storageKey = "appearanceMode"

    /// 첫 실행 시(저장값 없음/구버전 "system") 현재 시스템 외형을 기본값으로 심는다.
    /// 이후에는 사용자의 토글 선택을 따른다.
    static func seedDefaultFromSystemIfNeeded() {
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: storageKey), AppearanceMode(rawValue: raw) != nil {
            return
        }
        let systemIsDark = defaults.string(forKey: "AppleInterfaceStyle") == "Dark"
        defaults.set((systemIsDark ? AppearanceMode.dark : .light).rawValue, forKey: storageKey)
    }
}

/// 클릭 즉시 라이트↔다크를 전환하는 아이콘 버튼.
struct AppearanceMenu: View {
    @AppStorage(AppearanceMode.storageKey) private var appearanceMode: AppearanceMode = .dark

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                appearanceMode = appearanceMode.toggled
            }
        } label: {
            Image(systemName: appearanceMode.iconName)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(.lbPrimary)
                .frame(width: 56, height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.bgSecondary)
                }
                .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .help("라이트/다크 전환")
    }
}
