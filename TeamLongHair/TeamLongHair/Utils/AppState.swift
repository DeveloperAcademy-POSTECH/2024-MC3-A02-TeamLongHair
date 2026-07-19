//
//  AppState.swift
//  TeamLongHair
//
//  Created by Damin on 7/31/24.
//

import SwiftUI

@Observable
final class AppState {
    
    static let shared = AppState()
    // 초기값을 디폴트 단축키로 설정
    private var keyShortcut: KeyShortcut = KeyShortcut(modifierFlags: [.command, .control], keyCode: 40)
    var isPanelPresented: Bool = false
    var isArrowKeyToggle: Bool = false
    var arrowKey: ArrowKey = .up
    var shouldSaveDataToggle: Bool = false
    var pendingTabInfo: BrowserTabReader.TabInfo?
    /// 현재 열려 있는 프로젝트/페이지. 플로팅 패널이 저장 대상을 이 값에 맞춰
    /// 기본 선택하도록 하여, 캡처한 링크가 지금 보고 있는 캔버스에 저장되게 한다.
    var currentProjectID: UUID?
    var currentPageID: UUID?
    /// 최근 드롭 수집 결과(토스트/팝오버 확인용). 매번 새 id라 변경이 항상 감지된다.
    var lastIngest: IngestReceipt?

    private init() {
        migrateHotKeyDefaultIfNeeded()
        loadShortcutgKeys()
    }

    /// 현재 등록에 쓸 단축키(로드된 값).
    var currentShortcut: KeyShortcut { keyShortcut }

    /// 옛 기본 ⌘⇧G였던 사용자를 1회 ⌘⌃K로 옮긴다(직접 지정한 조합은 건드리지 않음).
    func migrateHotKeyDefaultIfNeeded() {
        let ud = UserDefaults.standard
        guard !ud.bool(forKey: "didMigrateHotKeyDefault") else { return }
        let savedKey = ud.integer(forKey: "shortcutKeyCode")
        let savedMods = UInt(ud.integer(forKey: "shortcutModifierFlags"))
        let oldDefault = NSEvent.ModifierFlags([.command, .shift]).rawValue
        if savedKey == 5 && savedMods == oldDefault {
            ud.set(40, forKey: "shortcutKeyCode")
            ud.set(NSEvent.ModifierFlags([.command, .control]).rawValue, forKey: "shortcutModifierFlags")
        }
        ud.set(true, forKey: "didMigrateHotKeyDefault")
    }

    func loadShortcutgKeys() {
        let userDefaults = UserDefaults.standard

        guard let savedKeyCode = userDefaults.object(forKey: "shortcutKeyCode") as? Int else {
            userDefaults.set(keyShortcut.keyCode, forKey: "shortcutKeyCode")
            return
        }
        
        guard let savedModifierFlagsValue = userDefaults.object(forKey: "shortcutModifierFlags") as? UInt else {
            userDefaults.set(keyShortcut.modifierFlags.rawValue, forKey: "shortcutModifierFlags")
            return
        }

       keyShortcut = KeyShortcut(modifierFlags: NSEvent.ModifierFlags(rawValue: savedModifierFlagsValue), keyCode: savedKeyCode)
        
    }
    
    /// 핫키가 눌리면 패널을 토글한다. 열릴 때 브라우저가 프론트인 지금 탭을 캡처한다.
    func handleHotKey() {
        if !isPanelPresented {
            pendingTabInfo = BrowserTabReader.readActiveTab()
        }
        isPanelPresented.toggle()
    }

    /// 패널 내부 키 조작만 담당한다(esc 닫기 / 방향키 이동 / enter 저장).
    /// 단축키 토글은 Carbon 핫키가 담당하므로 여기서 하지 않는다(이중 토글 방지).
    @discardableResult
    func checkLocalEventIsKeyShortcut(event: NSEvent) -> NSEvent {
        if event.keyCode == KeyShortcut.esc {
            isPanelPresented = false
            return event
        }
        if isPanelPresented && isArrowKey(Int(event.keyCode)) {
            for arrow in ArrowKey.allCases where arrow.key == event.keyCode {
                arrowKey = arrow
                break
            }
            isArrowKeyToggle.toggle()
        }
        if isPanelPresented && event.keyCode == KeyShortcut.enter {
            shouldSaveDataToggle.toggle()
        }
        return event
    }

    func isArrowKey(_ keyCode: Int) -> Bool {
        return ArrowKey.allCases.contains(where: { $0.key == keyCode })
    }
}

struct IngestReceipt: Equatable {
    let id: UUID
    let count: Int
    let targetName: String
    init(count: Int, targetName: String) {
        self.id = UUID()
        self.count = count
        self.targetName = targetName
    }
}
