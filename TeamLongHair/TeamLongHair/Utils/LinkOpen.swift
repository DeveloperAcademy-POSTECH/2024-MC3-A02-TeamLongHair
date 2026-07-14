//
//  LinkOpen.swift
//  TeamLongHair
//
//  링크 URL을 기본 브라우저에서 여는 공용 헬퍼.
//

import AppKit

extension Link {
    /// 링크의 URL을 기본 브라우저에서 연다. 스킴이 없으면 https를 붙인다.
    func openInBrowser() {
        var text = detail.URL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        if !text.contains("://") { text = "https://" + text }
        guard let url = URL(string: text) else { return }
        NSWorkspace.shared.open(url)
    }
}
