//
//  ProjectCardData.swift
//  TeamLongHair
//
//  프로젝트 카드 렌더에 필요한 파생값(전체 링크 수, 커버용 파비콘)을 뽑는다.
//

import Foundation

extension Project {
    /// 모든 페이지의 링크 트리를 평탄화한 전체 링크 수.
    var totalLinkCount: Int {
        pages.reduce(0) { $0 + $1.allLinks.count }
    }

    /// 커버 모자이크용 파비콘. host 기준 중복 제거 후 정렬 순서로 최대 max개.
    /// host를 못 구하면 URL 문자열을 키로 사용한다.
    func mosaicFavicons(max: Int = 9) -> [Data] {
        var seenKeys = Set<String>()
        var result: [Data] = []
        for page in pages {
            for link in page.allLinks {
                guard let data = link.detail.faviconData else { continue }
                let key = URL(string: link.detail.URL)?.host ?? link.detail.URL
                if seenKeys.contains(key) { continue }
                seenKeys.insert(key)
                result.append(data)
                if result.count >= max { return result }
            }
        }
        return result
    }
}
