# Carbon 핫키 전환 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 전역 단축키를 Carbon `RegisterEventHotKey`로 전환해 브라우저 충돌·Accessibility 권한 의존을 없애고, 기본 조합을 ⌘⌃K로 바꾼다.

**Architecture:** Carbon 핫키 래퍼(`HotKeyCenter` 싱글턴)가 시스템 레벨에서 조합을 가로채 `onHotKey`를 호출하고, AppState가 패널을 토글한다. NSEvent 글로벌 모니터는 제거하고, 패널 내 키 조작용 로컬 모니터만 남긴다. 순수 수정자 매핑(`HotKeyModifiers`)은 swiftc로 테스트한다.

**Tech Stack:** macOS 14+, SwiftUI, AppKit, Carbon(HIToolbox) `RegisterEventHotKey`, swiftc 기반 순수 로직 테스트.

## Global Constraints

- 전역 단축키는 Carbon `RegisterEventHotKey`로 구현한다(NSEvent 글로벌 모니터 사용 금지).
- 기본 조합은 **⌘⌃K**(command+control, keyCode 40)이다.
- 기존 ⌘⇧G(command+shift, keyCode 5) 사용자는 **조건부 1회 마이그레이션**(플래그 `didMigrateHotKeyDefault`); 직접 지정한 다른 조합은 건드리지 않는다.
- 설정 화면의 **커스텀 단축키 레코더를 유지**한다. 저장 시 핫키를 재등록하고, 등록 실패(조합 선점)면 이전 조합을 유지하고 "이미 사용 중" 안내를 띄운다.
- **Accessibility 권한은 사용도 요청도 하지 않는다.** 관련 코드/UI(손쉬운 사용 행·프롬프트·설정 이동)를 제거하고 Automation만 남긴다.
- 패널 내 키 조작(esc/방향키/enter)용 **로컬 모니터는 유지**한다.
- 앱이 프론트일 때도 핫키가 발동하므로, 로컬 모니터는 단축키 토글을 **하지 않는다**(이중 토글 방지).
- 순수 로직은 프레임워크 의존 없는 파일에 두어 `scripts/run_canvas_tests.sh`(swiftc)로 테스트 가능해야 한다.
- 새 Swift 파일은 `ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj <Group> <File.swift>`로 등록한다.
- 앱 빌드 검증: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build` → `** BUILD SUCCEEDED **`.
- 엔타이틀먼트/Info.plist 변경 없음.

---

## 파일 구조

**신규**
- `TeamLongHair/TeamLongHair/Utils/HotKeyModifiers.swift` — 순수 수정자 매핑(Foundation only, swiftc 테스트)
- `TeamLongHair/TeamLongHair/Utils/HotKeyCenter.swift` — Carbon 핫키 등록/해제 래퍼(싱글턴)

**수정**
- `TeamLongHair/TeamLongHair/Utils/AppState.swift` — handleHotKey, 마이그레이션, currentShortcut, 기본값, 로컬 핸들러 축소, 글로벌 핸들러 제거
- `TeamLongHair/TeamLongHair/Utils/AppDelegate.swift` — 글로벌 모니터 제거, 핫키 배선, permission refresh 제거
- `TeamLongHair/TeamLongHair/FloatingPanel/ShortcutSettingView.swift` — 저장 시 재등록 + 실패 안내
- `TeamLongHair/TeamLongHair/Utils/PermissionManager.swift` — accessibility API 제거
- `TeamLongHair/TeamLongHair/Utils/PermissionStatusView.swift` — 손쉬운 사용 행 제거
- `scripts/run_canvas_tests.sh`, `CanvasLogicTests/main.swift` — carbonMask 테스트

---

### Task 1: 순수 수정자 매핑 HotKeyModifiers (TDD)

프레임워크 의존이 없는 순수 함수. 유일하게 완전 TDD가 가능한 태스크.

**Files:**
- Create: `TeamLongHair/TeamLongHair/Utils/HotKeyModifiers.swift`
- Modify: `scripts/run_canvas_tests.sh` (swiftc 입력에 `HotKeyModifiers.swift` 추가)
- Test: `CanvasLogicTests/main.swift` (파일 끝 `if failures > 0` 직전에 케이스 추가)

**Interfaces:**
- Produces: `enum HotKeyModifiers { static let cmd/shift/option/control: UInt32; static func carbonMask(cocoaRawValue: UInt) -> UInt32 }`

- [ ] **Step 1: 테스트 추가 (실패 확인용)**

`CanvasLogicTests/main.swift`의 맨 끝, `if failures > 0 { ... }` 줄 **바로 위**에 추가한다. (NSEvent.ModifierFlags rawValue 비트: command=1<<20, shift=1<<17, option=1<<19, control=1<<18 — 안정 상수라 리터럴로 검증한다.)

```swift
// MARK: - HotKeyModifiers tests
do {
    let command: UInt = 1 << 20
    let shift: UInt = 1 << 17
    let option: UInt = 1 << 19
    let control: UInt = 1 << 18
    expectEqual(HotKeyModifiers.carbonMask(cocoaRawValue: 0), 0, "수정자 없음 → 0")
    expectEqual(HotKeyModifiers.carbonMask(cocoaRawValue: command), 256, "⌘ → cmdKey 256")
    expectEqual(HotKeyModifiers.carbonMask(cocoaRawValue: control), 4096, "⌃ → controlKey 4096")
    expectEqual(HotKeyModifiers.carbonMask(cocoaRawValue: shift), 512, "⇧ → shiftKey 512")
    expectEqual(HotKeyModifiers.carbonMask(cocoaRawValue: option), 2048, "⌥ → optionKey 2048")
    expectEqual(HotKeyModifiers.carbonMask(cocoaRawValue: command | control), 4352, "⌘⌃ → 4352")
    expectEqual(HotKeyModifiers.carbonMask(cocoaRawValue: command | shift), 768, "⌘⇧ → 768")
}
```

- [ ] **Step 2: 테스트 실행 → 컴파일 실패 확인**

Run: `bash scripts/run_canvas_tests.sh`
Expected: FAIL — `error: cannot find 'HotKeyModifiers' in scope`

- [ ] **Step 3: HotKeyModifiers.swift 작성**

`TeamLongHair/TeamLongHair/Utils/HotKeyModifiers.swift`:

```swift
//
//  HotKeyModifiers.swift
//  TeamLongHair
//
//  NSEvent 수정자 rawValue를 Carbon 수정자 마스크로 변환하는 순수 로직(프레임워크 의존 없음, swiftc 테스트 대상).
//

import Foundation

enum HotKeyModifiers {
    // Carbon 수정자 마스크(안정 상수: cmdKey/shiftKey/optionKey/controlKey).
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

- [ ] **Step 4: 테스트 러너에 순수 파일 등록**

`scripts/run_canvas_tests.sh`의 `swiftc -o "$OUT" \` 블록에서 `CaptureTargetResolver.swift` 줄 바로 아래에 한 줄 추가:

```bash
  TeamLongHair/TeamLongHair/Utils/HotKeyModifiers.swift \
```

- [ ] **Step 5: 테스트 실행 → 통과 확인**

Run: `bash scripts/run_canvas_tests.sh`
Expected: PASS — 마지막 줄 `ALL TESTS PASSED`

- [ ] **Step 6: 앱 프로젝트에 파일 등록**

Run:
```bash
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj Utils HotKeyModifiers.swift
```
Expected: `Added HotKeyModifiers.swift to group Utils`

- [ ] **Step 7: 앱 빌드 확인**

Run: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: 커밋**

```bash
git add TeamLongHair/TeamLongHair/Utils/HotKeyModifiers.swift \
        scripts/run_canvas_tests.sh CanvasLogicTests/main.swift \
        TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj
git commit -m "feat: Add HotKeyModifiers carbonMask pure logic with tests"
```

---

### Task 2: HotKeyCenter (Carbon 핫키 래퍼)

Carbon 핫키 등록/해제 싱글턴. 이 태스크에서는 파일이 컴파일되면 완료(아직 배선 안 함).

**Files:**
- Create: `TeamLongHair/TeamLongHair/Utils/HotKeyCenter.swift`

**Interfaces:**
- Produces: `@MainActor final class HotKeyCenter { static let shared; var onHotKey: (() -> Void)?; @discardableResult func register(keyCode: UInt32, carbonModifiers: UInt32) -> Bool; func unregister() }`

- [ ] **Step 1: HotKeyCenter.swift 작성**

`TeamLongHair/TeamLongHair/Utils/HotKeyCenter.swift`:

```swift
//
//  HotKeyCenter.swift
//  TeamLongHair
//
//  Carbon RegisterEventHotKey 래퍼. 시스템 레벨에서 조합을 가로채므로 브라우저로 새지 않고
//  Accessibility 권한도 필요 없다. AppDelegate와 설정 레코더가 공유하는 싱글턴.
//

import AppKit
import Carbon

@MainActor
final class HotKeyCenter {
    static let shared = HotKeyCenter()

    /// 핫키가 눌렸을 때 호출된다.
    var onHotKey: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var handlerInstalled = false
    private let signature: OSType = 0x54_4C_48_4B  // 'TLHK'

    private init() {}

    /// 주어진 keyCode/Carbon 수정자로 핫키를 (재)등록한다. 이전 핫키는 해제한다.
    /// 등록 실패(조합 선점/무효)면 false를 반환한다.
    @discardableResult
    func register(keyCode: UInt32, carbonModifiers: UInt32) -> Bool {
        installHandlerIfNeeded()
        unregister()
        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: signature, id: 1)
        let status = RegisterEventHotKey(keyCode, carbonModifiers, hotKeyID,
                                         GetApplicationEventTarget(), 0, &ref)
        guard status == noErr, let ref else { return false }
        hotKeyRef = ref
        return true
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }

    private func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData -> OSStatus in
            guard let userData else { return noErr }
            let center = Unmanaged<HotKeyCenter>.fromOpaque(userData).takeUnretainedValue()
            MainActor.assumeIsolated { center.onHotKey?() }
            return noErr
        }, 1, &spec, selfPtr, nil)
        handlerInstalled = true
    }
}
```

주: `import Carbon`로 HIToolbox 심볼이 노출되지 않으면 `import Carbon.HIToolbox`로 바꾼다. C 콜백은 캡처가 없어야 하므로 `self`는 `userData`로 전달한다. 콜백은 메인 이벤트 디스패처에서 실행되므로 `MainActor.assumeIsolated`로 `onHotKey`를 호출한다.

- [ ] **Step 2: 파일 등록**

Run:
```bash
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj Utils HotKeyCenter.swift
```
Expected: `Added HotKeyCenter.swift to group Utils`

- [ ] **Step 3: 빌드 확인**

Run: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: 커밋**

```bash
git add TeamLongHair/TeamLongHair/Utils/HotKeyCenter.swift \
        TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj
git commit -m "feat: Add HotKeyCenter Carbon RegisterEventHotKey wrapper"
```

---

### Task 3: 핫키 라이브 배선 — AppState + AppDelegate

AppState와 AppDelegate를 함께 바꾼다. 글로벌 핸들러 제거와 그 호출부 제거는 분리하면 빌드가 깨지므로 한 태스크로 묶는다. 이 태스크가 끝나면 ⌘⌃K가 실제로 동작한다.

**Files:**
- Modify: `TeamLongHair/TeamLongHair/Utils/AppState.swift`
- Modify: `TeamLongHair/TeamLongHair/Utils/AppDelegate.swift`

**Interfaces:**
- Consumes: `HotKeyModifiers.carbonMask(cocoaRawValue:)`(Task 1), `HotKeyCenter.shared`/`register`/`unregister`/`onHotKey`(Task 2), 기존 `BrowserTabReader.readActiveTab()`, `KeyShortcut(modifierFlags:keyCode:)`.
- Produces: `AppState.handleHotKey()`, `AppState.migrateHotKeyDefaultIfNeeded()`, `AppState.currentShortcut: KeyShortcut`.

- [ ] **Step 1: AppState 기본값 변경**

`TeamLongHair/TeamLongHair/Utils/AppState.swift`의 15행:
```swift
    private var keyShortcut: KeyShortcut = KeyShortcut(modifierFlags: [.command, .shift], keyCode: 5)
```
를
```swift
    private var keyShortcut: KeyShortcut = KeyShortcut(modifierFlags: [.command, .control], keyCode: 40)
```
로 교체(⌘⌃K).

- [ ] **Step 2: AppState.init에 마이그레이션 + currentShortcut 추가**

`private init()`(26–28행)를 교체:
```swift
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
```

- [ ] **Step 3: AppState에 handleHotKey 추가, 글로벌 핸들러 제거, 로컬 핸들러 축소**

`checkLocalEventIsKeyShortcut(event:)`(47–80행)와 `checkGlobalEventIsKeyShortcut(event:)`(82–93행) 전체를 다음으로 교체(글로벌 핸들러 삭제, 로컬 핸들러는 esc/방향키/enter만, 그리고 handleHotKey 추가):

```swift
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
```

(주: `checkGlobalEventIsKeyShortcut`는 완전히 삭제된다. `loadShortcutgKeys()`/`isArrowKey(_:)`는 그대로 둔다.)

- [ ] **Step 4: AppDelegate 재작성**

`TeamLongHair/TeamLongHair/Utils/AppDelegate.swift` 전체를 교체:

```swift
//
//  AppDelegate.swift
//  TeamLongHair
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private let appState = AppState.shared
    private var localKeyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 전역 단축키는 Carbon 핫키로 등록한다(권한 불필요, 브라우저로 안 샘).
        HotKeyCenter.shared.onHotKey = { AppState.shared.handleHotKey() }
        let s = appState.currentShortcut
        _ = HotKeyCenter.shared.register(
            keyCode: UInt32(s.keyCode),
            carbonModifiers: HotKeyModifiers.carbonMask(cocoaRawValue: s.modifierFlags.rawValue))

        startMonitoringKeys()   // 패널 내부 키용 로컬 모니터만 남는다.
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
```

(주: 글로벌 모니터·`PermissionManager.shared.refresh()` 호출이 사라진다. 마이그레이션/로드는 `AppState.init`이 이미 수행한다.)

- [ ] **Step 5: 빌드 확인**

Run: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: 수동 QA(참고 — GUI는 실행 환경에서 불가)**

정적으로 확인: 글로벌 모니터 참조가 남아있지 않은지(`grep -n "addGlobalMonitorForEvents\|checkGlobalEventIsKeyShortcut" TeamLongHair` → 매치 없음), 핫키 배선·로컬 모니터가 온전한지. 실기기 QA는 Task 5 이후 사용자에게 이관.

- [ ] **Step 7: 커밋**

```bash
git add TeamLongHair/TeamLongHair/Utils/AppState.swift \
        TeamLongHair/TeamLongHair/Utils/AppDelegate.swift
git commit -m "feat: Wire Carbon hotkey, drop global monitor, migrate default to Cmd-Ctrl-K"
```

---

### Task 4: 설정 레코더 재등록 + 실패 안내

새 조합 저장 시 핫키를 재등록하고, 실패하면 이전 조합을 유지하고 안내한다.

**Files:**
- Modify: `TeamLongHair/TeamLongHair/FloatingPanel/ShortcutSettingView.swift`

**Interfaces:**
- Consumes: `HotKeyCenter.shared.register(keyCode:carbonModifiers:)`(Task 2), `HotKeyModifiers.carbonMask(cocoaRawValue:)`(Task 1), `AppState.shared.loadShortcutgKeys()`(기존).

- [ ] **Step 1: 에러 메시지 상태 추가**

`ShortcutSettingsView`의 `@State private var localKeyMonitor: Any?`(12행) 아래에 추가:
```swift
    @State private var errorMessage: String?
```

- [ ] **Step 2: saveShortcut 교체**

`saveShortcut()`(83–89행)를 교체:
```swift
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
```

- [ ] **Step 3: 에러 메시지 표시**

`Button("Save Shortcut") { saveShortcut() }` 블록(63–66행) **아래**, 같은 VStack 안에 추가:
```swift
                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
```

- [ ] **Step 4: 빌드 확인**

Run: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: 커밋**

```bash
git add TeamLongHair/TeamLongHair/FloatingPanel/ShortcutSettingView.swift
git commit -m "feat: Re-register hotkey on shortcut save with in-use warning"
```

---

### Task 5: 권한 UI 정리 (Accessibility 제거)

Accessibility가 불필요해졌으므로 관련 API·UI를 제거하고 Automation만 남긴다.

**Files:**
- Modify: `TeamLongHair/TeamLongHair/Utils/PermissionManager.swift`
- Modify: `TeamLongHair/TeamLongHair/Utils/PermissionStatusView.swift`

**Interfaces:**
- Produces: `PermissionManager` (accessibility 없이 `openAutomationSettings()`만).

- [ ] **Step 1: PermissionManager에서 accessibility 제거**

`TeamLongHair/TeamLongHair/Utils/PermissionManager.swift` 전체를 교체:
```swift
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
```

- [ ] **Step 2: PermissionStatusView에서 손쉬운 사용 행 제거**

`TeamLongHair/TeamLongHair/Utils/PermissionStatusView.swift`의 `struct PermissionStatusView`의 `body`(16–41행)를 교체(손쉬운 사용 행·`scenePhase`/`refresh` 제거, 자동화 행만):
```swift
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            permissionRow(
                title: "자동화 (브라우저 제어)",
                reason: "현재 탭의 주소·제목을 자동으로 가져오기 위해 필요합니다. 처음 저장할 때 허용 창이 뜹니다.",
                state: .info
            ) {
                Button("설정 열기") { manager.openAutomationSettings() }
            }
        }
    }
```

그리고 같은 struct 상단의 `@Environment(\.scenePhase) private var scenePhase`(14행)를 **삭제**한다(더 이상 refresh를 트리거하지 않음). `@State private var manager = PermissionManager.shared`는 유지.

- [ ] **Step 3: 빌드 확인**

Run: `xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair -configuration Debug -destination 'platform=macOS' build`
Expected: `** BUILD SUCCEEDED **`
(빌드가 미사용 `PermissionState.granted/.needed`를 오류로 취급하지 않는다 — 경고도 없어야 한다. 만약 미사용 심볼 경고가 뜨면 `statusIcon`/`PermissionState`에서 쓰지 않는 케이스를 정리한다.)

- [ ] **Step 4: 커밋**

```bash
git add TeamLongHair/TeamLongHair/Utils/PermissionManager.swift \
        TeamLongHair/TeamLongHair/Utils/PermissionStatusView.swift
git commit -m "refactor: Drop Accessibility permission UI now that hotkey needs none"
```

---

## 실행 순서/의존성 요약

1. **Task 1** — 순수 매핑(carbonMask), 완전 TDD. 이후 모든 배선의 기반.
2. **Task 2** — HotKeyCenter(Carbon 래퍼), 컴파일만.
3. **Task 3** — AppState+AppDelegate 라이브 배선(글로벌 모니터 제거, ⌘⌃K 마이그레이션). 여기서 핫키 동작.
4. **Task 4** — 설정 레코더 재등록 + 실패 안내.
5. **Task 5** — 권한 UI 정리.

각 태스크는 빌드 성공(Task 1은 로직 테스트 통과)으로 게이트한다. Carbon/AppKit 경로(Task 2–5)는 자동 테스트가 불가하므로 빌드 + 명시된 수동 QA로 검증한다 — 이 코드베이스의 알려진 제약이다. 전체 완료 후 사용자 실기기 QA: ⌘⌃K로 브라우저 프론트에서 패널 열림(권한 없이), 브라우저 단축키 미발동, 이중 토글 없음, 설정 재지정·선점 안내, ⌘⇧G 마이그레이션, 권한 화면에서 손쉬운 사용 사라짐.
