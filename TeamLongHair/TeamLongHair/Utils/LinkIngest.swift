//
//  LinkIngest.swift
//  TeamLongHair
//
//  URL → 노드 생성의 단일 출처. 플로팅 패널·메뉴바·캔버스 드롭이 모두 이걸 쓴다.
//

import Foundation
import SwiftData

@MainActor
enum LinkIngest {
    /// URL 하나를 page(또는 parent 하위)에 노드로 추가하고 메타데이터 취득을 건다.
    /// title 미지정 시 빈 문자열로 두어 LinkMetadataApply가 실제 제목을 채우게 한다.
    @discardableResult
    static func addLink(url: URL, title: String = "",
                        to page: Page, parent: Link? = nil) -> Link {
        let detail = LinkDetail(URL: url.absoluteString, title: title)
        let siblings = parent?.sortedSubLinks ?? page.sortedLinks
        let link = Link(detail: detail, sortIndex: (siblings.last?.sortIndex ?? -1) + 1)
        if let parent {
            parent.subLinks.append(link)
        } else {
            page.links.append(link)
        }
        LinkMetadataApply.fetchAndApply(to: detail)
        return link
    }

    /// 여러 URL을 같은 대상에 추가하고 추가된 개수를 반환.
    @discardableResult
    static func addLinks(_ urls: [URL], to page: Page, parent: Link? = nil) -> Int {
        for url in urls { addLink(url: url, to: page, parent: parent) }
        return urls.count
    }
}
