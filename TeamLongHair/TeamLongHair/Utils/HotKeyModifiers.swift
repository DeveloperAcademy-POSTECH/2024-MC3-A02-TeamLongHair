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
