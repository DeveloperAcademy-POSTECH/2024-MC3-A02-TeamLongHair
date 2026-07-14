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

    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
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

/// 어디서든 재사용 가능한 화면 모드 전환 버튼(아이콘 → 드롭다운으로 3가지 선택).
struct AppearanceMenu: View {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    var body: some View {
        Menu {
            Picker("화면 모드", selection: $appearanceMode) {
                ForEach(AppearanceMode.allCases) { mode in
                    Label(mode.label, systemImage: mode.iconName).tag(mode)
                }
            }
            .pickerStyle(.inline)
        } label: {
            Image(systemName: appearanceMode.iconName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.lbPrimary)
                .frame(width: 32, height: 32)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.bgSecondary)
                }
                .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("화면 모드")
    }
}
