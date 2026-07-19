//
//  ProjectCardFormatting.swift
//  TeamLongHair
//
//  프로젝트 카드용 순수 포맷팅(색조/모노그램/상대날짜). 프레임워크 의존 없음(swiftc 테스트 대상).
//

import Foundation

enum ProjectCardFormatting {
    /// 제목을 결정적 해시(FNV-1a)로 0.0..<1.0 색조로 변환. Swift 기본 Hasher는 실행마다
    /// 시드가 달라 색이 바뀌므로 쓰지 않는다.
    static func stableHue(for title: String) -> Double {
        var hash: UInt64 = 0xcbf29ce484222325
        for scalar in title.unicodeScalars {
            hash ^= UInt64(scalar.value)
            hash = hash &* 0x100000001b3
        }
        return Double(hash % 360) / 360.0
    }

    /// 표시용 첫 글자(대문자). 공백/빈 문자열이면 "?".
    static func monogram(for title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "?" }
        return String(first).uppercased()
    }

    /// 상대 편집 라벨. now를 주입받아 테스트 가능. 달력 일자 경계(자정) 기준.
    /// 같은 날 → "오늘 편집", 하루 전 → "어제 편집", 그 외 → "N일 전 편집". 미래는 "오늘 편집".
    static func relativeEditLabel(from date: Date, now: Date,
                                  calendar: Calendar = .current) -> String {
        let startOfDate = calendar.startOfDay(for: date)
        let startOfNow = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: startOfDate, to: startOfNow).day ?? 0
        switch days {
        case ..<1: return "오늘 편집"
        case 1:    return "어제 편집"
        default:   return "\(days)일 전 편집"
        }
    }
}
