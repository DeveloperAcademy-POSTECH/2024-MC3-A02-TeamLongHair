# 전역 단축키 Carbon RegisterEventHotKey 전환 — 설계

**날짜:** 2026-07-19
**상태:** 승인 대기(사용자 검토)

## 배경 / 목적

현재 전역 단축키(기본 ⌘⇧G)는 `NSEvent.addGlobalMonitorForEvents`로 구현되어 두 가지 약점이 있다:

1. **키를 소비하지 않는다** — 글로벌 모니터는 이벤트를 관찰만 하고 소비하지 않으므로, 브라우저가 쓰는 조합(⌘⇧G = 찾기 이전, Finder 폴더 이동 등)을 고르면 그 키가 **브라우저 동작 + 우리 패널** 둘 다 발동한다.
2. **손쉬운 사용(Accessibility) 권한이 필요하다** — 글로벌 모니터가 이 권한의 유일한 소비처이며, OS 업데이트마다 권한이 무효화되는 문제가 있었다.

**Carbon `RegisterEventHotKey`** 로 바꾸면 시스템이 해당 조합을 **예약·가로채** 브라우저로 새지 않고, **Accessibility 권한도 불필요**해진다. 기본 조합도 브라우저 충돌이 적은 **⌘⌃K**로 변경한다.

## 목표 / 비목표

**목표**
- 전역 단축키를 Carbon `RegisterEventHotKey`로 전환(글로벌 NSEvent 모니터 제거).
- 기본 조합을 ⌘⇧G → **⌘⌃K**로 변경, 기존 ⌘⇧G 사용자는 조건부 1회 마이그레이션.
- 설정 화면의 **커스텀 단축키 레코더 유지** — 저장 시 핫키 재등록, 조합 선점 시 안내.
- Accessibility가 불필요해지므로 **권한 온보딩/상태 UI에서 Accessibility 제거**(Automation만 유지).
- 패널 내 키 조작(esc/방향키/enter)용 **로컬 모니터는 유지**.

**비목표(YAGNI)**
- 다중 전역 단축키(패널 열기 외 추가 액션) — 불필요.
- 외부 SPM 라이브러리 도입 — 의존성 0 유지.
- Automation 권한 흐름 변경 — 그대로 둔다(탭 자동 읽기용).

## 아키텍처 개요

```
사용자가 ⌘⌃K 누름(어느 앱에서든)
        │  Carbon가 시스템 레벨에서 가로챔(브라우저로 안 샘, 권한 불필요)
        ▼
HotKeyCenter (InstallEventHandler → kEventHotKeyPressed)
        │  onHotKey()
        ▼
AppState.handleHotKey()  →  (열기면) BrowserTabReader.readActiveTab() → pendingTabInfo
                            isPanelPresented.toggle()
        ▼
FloatingPanelView 표시/숨김 (기존 그대로)

패널 내부 키(esc/방향키/enter): 기존 localKeyMonitor → AppState.checkLocalEventIsKeyShortcut (토글 분기 제거)
```

## 컴포넌트 상세

### 1. HotKeyCenter (신규, `Utils/HotKeyCenter.swift`, 싱글턴 `@MainActor`)

Carbon 핫키 등록/해제 래퍼. AppDelegate와 설정 레코더가 같은 인스턴스를 쓰도록 `shared` 싱글턴.

```swift
import Carbon
import AppKit

@MainActor
final class HotKeyCenter {
    static let shared = HotKeyCenter()

    /// 핫키가 눌렸을 때 호출된다.
    var onHotKey: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var handlerInstalled = false
    private let signature: OSType = 0x54_4C_48_4B  // 'TLHK'

    private init() {}

    /// 주어진 keyCode/Carbon 수정자로 핫키를 (재)등록한다.
    /// 이전 핫키는 해제한다. 등록 실패(조합 선점/무효)면 false.
    @discardableResult
    func register(keyCode: UInt32, carbonModifiers: UInt32) -> Bool {
        installHandlerIfNeeded()
        unregister()
        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: signature, id: 1)
        let status = RegisterEventHotKey(keyCode, carbonModifiers, hotKeyID,
                                         GetEventDispatcherTarget(), 0, &ref)
        guard status == noErr, let ref else { return false }
        hotKeyRef = ref
        return true
    }

    func unregister() {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref); hotKeyRef = nil }
    }

    private func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetEventDispatcherTarget(), { _, _, userData in
            guard let userData else { return noErr }
            let center = Unmanaged<HotKeyCenter>.fromOpaque(userData).takeUnretainedValue()
            MainActor.assumeIsolated { center.onHotKey?() }
            return noErr
        }, 1, &spec, selfPtr, nil)
        handlerInstalled = true
    }
}
```

- 핸들러 콜백은 메인 이벤트 디스패처에서 호출된다(메인 스레드) → `MainActor.assumeIsolated`로 `onHotKey` 호출.
- 등록 실패 시 `hotKeyRef`는 nil로 남으며 크래시 없음.

### 2. 순수 매핑 (신규, `Utils/HotKeyModifiers.swift`, Foundation only → swiftc 테스트)

NSEvent 수정자 rawValue를 Carbon 수정자 마스크로 변환. 프레임워크 의존 없이 비트만 다룬다(Carbon 상수는 안정적: cmdKey=256, shiftKey=512, optionKey=2048, controlKey=4096; NSEvent rawValue 비트: command=1<<20, shift=1<<17, option=1<<19, control=1<<18).

```swift
import Foundation

enum HotKeyModifiers {
    // Carbon 수정자 마스크(안정 상수).
    static let cmd: UInt32 = 256
    static let shift: UInt32 = 512
    static let option: UInt32 = 2048
    static let control: UInt32 = 4096

    // NSEvent.ModifierFlags rawValue 비트.
    private static let cocoaCommand: UInt = 1 << 20
    private static let cocoaShift: UInt = 1 << 17
    private static let cocoaOption: UInt = 1 << 19
    private static let cocoaControl: UInt = 1 << 18

    /// NSEvent.ModifierFlags.rawValue → Carbon 수정자 마스크.
    static func carbonMask(cocoaRawValue raw: UInt) -> UInt32 {
        var mask: UInt32 = 0
        if raw & cocoaCommand != 0 { mask |= cmd }
        if raw & cocoaShift   != 0 { mask |= shift }
        if raw & cocoaOption  != 0 { mask |= option }
        if raw & cocoaControl != 0 { mask |= control }
        return mask
    }
}
```

- 예: ⌘⌃ → `cmd | control` = 256 + 4096 = 4352.

### 3. AppState 변경 (`Utils/AppState.swift`)

- **삭제**: `checkGlobalEventIsKeyShortcut(event:)` (글로벌 모니터 제거).
- **추가**: 핫키 눌림 시 토글 로직.
  ```swift
  func handleHotKey() {
      if !isPanelPresented {
          pendingTabInfo = BrowserTabReader.readActiveTab()   // 브라우저 프론트일 때 캡처
      }
      isPanelPresented.toggle()
  }
  ```
- **수정**: `checkLocalEventIsKeyShortcut(event:)`에서 **단축키 토글 분기 제거**(esc/방향키/enter만 유지). 이유: Carbon 핫키가 앱이 프론트일 때도 발동하므로, 로컬 모니터가 같은 키를 또 토글하면 이중 토글(무효화)된다.
  - 유지: esc → `isPanelPresented = false`; 패널 열림 상태에서 방향키 → `isArrowKeyToggle`; enter → `shouldSaveDataToggle`.
- `loadShortcutgKeys()`의 기본값을 `KeyShortcut(modifierFlags: [.command, .control], keyCode: 40)` (⌘⌃K)로 변경.
- **현재 KeyShortcut 노출**: 등록에 쓰도록 저장된 keyShortcut을 읽는 접근자를 둔다(예: `var currentShortcut: KeyShortcut { keyShortcut }` 또는 loadShortcutgKeys가 반환). AppDelegate가 이를 읽어 `HotKeyCenter.register`에 넘긴다.

**마이그레이션(1회, 멱등)**: 앱 시작 시 — 저장된 조합이 옛 기본 **⌘⇧G(command+shift, keyCode 5)** 이고 `didMigrateHotKeyDefault` 플래그가 없으면, ⌘⌃K로 덮어쓰고 플래그를 세운다. 사용자가 직접 지정한 다른 조합은 건드리지 않는다.
```swift
func migrateHotKeyDefaultIfNeeded() {
    let ud = UserDefaults.standard
    guard !ud.bool(forKey: "didMigrateHotKeyDefault") else { return }
    let savedKey = ud.integer(forKey: "shortcutKeyCode")
    let savedMods = UInt(ud.integer(forKey: "shortcutModifierFlags"))
    let oldDefault = NSEvent.ModifierFlags([.command, .shift]).rawValue
    if savedKey == 5 && savedMods == oldDefault {
        ud.set(40, forKey: "shortcutKeyCode")                                  // K
        ud.set(NSEvent.ModifierFlags([.command, .control]).rawValue,
               forKey: "shortcutModifierFlags")
    }
    ud.set(true, forKey: "didMigrateHotKeyDefault")
}
```
`migrateHotKeyDefaultIfNeeded()`는 `loadShortcutgKeys()`보다 먼저 호출한다(AppState.init 또는 AppDelegate 시작 시).

### 4. AppDelegate 변경 (`Utils/AppDelegate.swift`)

- **삭제**: `globalKeyMonitor` 프로퍼티, `addGlobalMonitorForEvents` 등록/해제.
- **유지**: `localKeyMonitor`(패널 조작).
- **삭제**: `PermissionManager.shared.refresh()` 호출.
- **추가**: 시작 시 핫키 배선.
  ```swift
  func applicationDidFinishLaunching(_ notification: Notification) {
      appState.migrateHotKeyDefaultIfNeeded()
      appState.loadShortcutgKeys()
      HotKeyCenter.shared.onHotKey = { AppState.shared.handleHotKey() }
      let s = appState.currentShortcut
      _ = HotKeyCenter.shared.register(
          keyCode: UInt32(s.keyCode),
          carbonModifiers: HotKeyModifiers.carbonMask(cocoaRawValue: s.modifierFlags.rawValue))
      startMonitoringKeys()   // 로컬 모니터만 남음
  }
  ```
- `startMonitoringKeys`/`stopMonitoringKeys`는 로컬 모니터만 다루도록 축소. `applicationWillTerminate`에서 `HotKeyCenter.shared.unregister()`도 호출.

### 5. 설정 레코더 (`FloatingPanel/ShortcutSettingView.swift`)

- `saveShortcut()`에서 UserDefaults 기록 후 **재등록**:
  ```swift
  let ok = HotKeyCenter.shared.register(
      keyCode: UInt32(shortcut.keyCode),
      carbonModifiers: HotKeyModifiers.carbonMask(cocoaRawValue: shortcut.modifierFlags.rawValue))
  ```
- 실패(`ok == false`, 조합 선점/무효) → **이전 조합 유지**(UserDefaults 되돌리기 + 직전 조합으로 재등록), 화면에 "이미 사용 중입니다 — 다른 조합을 선택하세요" 메시지 표시(`@State private var errorMessage: String?`). 성공 시 메시지 지움.
- 저장 성공 시 AppState의 in-memory 조합도 최신화되도록 `appState.loadShortcutgKeys()` 재호출(또는 currentShortcut 갱신).

### 6. 권한 UI 정리

- `Utils/PermissionManager.swift`: `accessibilityGranted`, `refresh()`, `promptAccessibility()`, `openAccessibilitySettings()` **삭제**. `openAutomationSettings()`와 `open(_:)`만 유지. (클래스가 비면 유지할 최소 API만 남긴다.)
- `Utils/PermissionStatusView.swift`: **손쉬운 사용 행 삭제**, 자동화 행만 유지. accessibility 관련 상태/버튼/`scenePhase refresh` 제거. `PermissionState`에서 미사용 케이스 정리.
- `PermissionOnboardingSheet`: 문구는 유지하되 이제 Automation만 표시된다. "탭 자동 저장을 쓰려면 아래 권한이 필요합니다" 문구는 그대로 적합.
- `HomeView` 온보딩 시트 배선은 변경 없음.

### 7. 오류 처리

- 등록 실패: 크래시 없음. 시작 시 실패면 로그만 남기고 진행(설정에서 재지정). 설정 저장 실패면 이전 조합 유지 + 안내.
- 마이그레이션: 플래그로 1회만, 멱등.
- 핸들러 콜백: 메인 스레드에서 실행(`MainActor.assumeIsolated`).

### 8. 테스트

**순수 로직(swiftc, `scripts/run_canvas_tests.sh` 확장)**
- `HotKeyModifiers.carbonMask(cocoaRawValue:)`:
  - ⌘ 단독 → 256; ⌃ 단독 → 4096.
  - ⌘⌃ → 4352; ⌘⇧ → 768.
  - 수정자 없음 → 0.

**수동 QA(Carbon/AppKit — swiftc 불가)**
- 브라우저가 프론트인 상태에서 ⌘⌃K → 패널이 뜨고 현재 탭 URL/제목 자동 채움(권한 프롬프트 없이).
- 브라우저에서 ⌘⌃K가 브라우저 동작을 일으키지 않음(가로채짐).
- 앱이 프론트일 때 ⌘⌃K → 이중 토글 없이 한 번만 토글.
- 설정에서 새 조합 녹음·저장 → 즉시 반영. 이미 쓰이는 조합(예: ⌘Space) 저장 시 "이미 사용 중" 안내 + 이전 조합 유지.
- 기존 ⌘⇧G 사용자 → 첫 실행 후 ⌘⌃K로 마이그레이션(직접 바꾼 조합은 유지).
- 손쉬운 사용 권한을 꺼도 단축키가 정상 동작(더 이상 불필요).
- 온보딩/설정 권한 화면에 손쉬운 사용 행이 사라지고 자동화만 남음.
- 패널 내 esc/방향키/enter 정상.

## 파일 요약

| 파일 | 변경 |
|---|---|
| `Utils/HotKeyCenter.swift` | 신규 — Carbon 핫키 래퍼(싱글턴) |
| `Utils/HotKeyModifiers.swift` | 신규 — 순수 수정자 매핑(테스트 대상) |
| `Utils/AppState.swift` | 수정 — handleHotKey, 로컬 핸들러 축소, 기본값/마이그레이션, currentShortcut |
| `Utils/AppDelegate.swift` | 수정 — 글로벌 모니터 제거, 핫키 배선, refresh 호출 제거 |
| `FloatingPanel/ShortcutSettingView.swift` | 수정 — 저장 시 재등록 + 실패 안내 |
| `Utils/PermissionManager.swift` | 수정 — accessibility API 제거 |
| `Utils/PermissionStatusView.swift` | 수정 — 손쉬운 사용 행 제거 |
| `scripts/run_canvas_tests.sh`, `CanvasLogicTests/main.swift` | 확장 — carbonMask 테스트 |

**엔타이틀먼트/Info.plist 변경 없음.** Accessibility는 사용조차 안 하게 되고(요청/체크 코드 삭제), Automation(NSAppleEventsUsageDescription)만 유지된다.
