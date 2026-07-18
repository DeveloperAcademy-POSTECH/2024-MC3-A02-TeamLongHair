//
//  LinkMetadataApply.swift
//  TeamLongHair
//
//  LinkMetadataService로 취득한 값을 LinkDetail에 반영한다(메인 액터).
//

import Foundation

@MainActor
enum LinkMetadataApply {
    /// detail.URL로 메타데이터를 취득해 반영한다.
    /// force=false면 이미 파비콘이 있으면 건너뛴다(중복 취득 방지).
    static func fetchAndApply(to detail: LinkDetail, force: Bool = false) {
        if !force && detail.faviconData != nil { return }
        let urlString = detail.URL
        Task { @MainActor in
            guard let m = await LinkMetadataService.fetch(urlString: urlString) else { return }
            if let t = m.title, detail.title.trimmingCharacters(in: .whitespaces).isEmpty {
                detail.title = t
            }
            if let f = m.faviconData { detail.faviconData = f }
            if let th = m.thumbnailData { detail.thumbnailData = th }
            if let d = m.description { detail.pageDescription = d }
        }
    }
}
