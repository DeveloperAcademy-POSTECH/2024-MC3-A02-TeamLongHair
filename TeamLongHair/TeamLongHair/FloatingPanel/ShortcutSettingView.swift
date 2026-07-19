//
//  ShortcutSettingView.swift
//  TeamLongHair
//
//  Created by Damin on 7/31/24.
//

import SwiftUI

struct ShortcutSettingsView: View {
    @State private var shortcut: KeyShortcut?
    @State private var localKeyMonitor: Any?
    @State private var errorMessage: String?
    @AppStorage(AppearanceMode.storageKey) private var appearanceMode: AppearanceMode = .dark

    init() {
        // UserDefaults에서 저장된 값을 불러와서 초기화
        let keyCode = UserDefaults.standard.integer(forKey: "shortcutKeyCode")
        let modifierFlagsValue = UserDefaults.standard.integer(forKey: "shortcutModifierFlags")
        let modifierFlags = NSEvent.ModifierFlags(rawValue: UInt(modifierFlagsValue))
        
        // shortcut State 변수의 초기값 설정
        if keyCode != 0 || modifierFlagsValue != 0 {
            _shortcut = State(initialValue: KeyShortcut(modifierFlags: modifierFlags, keyCode: keyCode))
        } else {
            _shortcut = State(initialValue: nil)
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("권한")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                PermissionStatusView()
            }

            Divider()

            VStack(spacing: 8) {
                Text("화면 모드")
                Picker("화면 모드", selection: $appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Label(mode.label, systemImage: mode.iconName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            }

            Divider()

            VStack(spacing: 8) {
                Text("Press your desired shortcut")
                Text(shortcut?.description ?? "No shortcut set")
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .onTapGesture {
                        startListeningForShortcut()
                    }
                Button("Save Shortcut") {
                    saveShortcut()
                }
                .disabled(shortcut == nil)
                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .frame(minWidth: 320)
        .onDisappear {
            stopMonitoringKeys()
        }
    }

    func startListeningForShortcut() {
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            shortcut = .init(modifierFlags: event.modifierFlags, keyCode: Int(event.keyCode))
            return event
        }
    }

    func saveShortcut() {
        guard let shortcut else { return }
        let ud = UserDefaults.standard
        let prevKey = ud.integer(forKey: "shortcutKeyCode")
        let prevMods = ud.integer(forKey: "shortcutModifierFlags")

        let ok = HotKeyCenter.shared.register(
            keyCode: UInt32(shortcut.keyCode),
            carbonModifiers: HotKeyModifiers.carbonMask(cocoaRawValue: shortcut.modifierFlags.rawValue))
        if ok {
            ud.set(shortcut.keyCode, forKey: "shortcutKeyCode")
            ud.set(shortcut.modifierFlags.rawValue, forKey: "shortcutModifierFlags")
            AppState.shared.loadShortcutgKeys()
            errorMessage = nil
        } else {
            // 이전 조합으로 되돌려 재등록(등록 상태를 일관되게 유지).
            _ = HotKeyCenter.shared.register(
                keyCode: UInt32(prevKey),
                carbonModifiers: HotKeyModifiers.carbonMask(cocoaRawValue: UInt(prevMods)))
            errorMessage = "이미 사용 중인 조합입니다. 다른 조합을 선택하세요."
        }
        stopMonitoringKeys()
    }
    
    func stopMonitoringKeys() {
        if let localKeyMonitor = self.localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }
    }
}
