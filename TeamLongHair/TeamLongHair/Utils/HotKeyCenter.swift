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
