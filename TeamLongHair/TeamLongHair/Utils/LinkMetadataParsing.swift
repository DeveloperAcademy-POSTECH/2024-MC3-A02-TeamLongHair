//
//  LinkMetadataParsing.swift
//  TeamLongHair
//
//  URL 정규화와 HTML description 추출(순수 함수). 프레임워크 의존 없음(swiftc 테스트 대상).
//

import Foundation

enum LinkMetadataParsing {
    /// 스킴이 없으면 https를 붙인다. host가 없거나 파싱 실패면 nil.
    static func normalizedURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let withScheme = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let url = URL(string: withScheme), url.host != nil else { return nil }
        return url
    }

    /// URL 문자열에서 표시용 호스트를 뽑는다. "www." 접두는 제거(뒤에 도메인이 남을 때만). host가 없으면 nil.
    static func displayHost(fromURLString raw: String) -> String? {
        guard let url = normalizedURL(from: raw), let rawHost = url.host else { return nil }
        var host = rawHost.lowercased()
        if host.hasPrefix("www.") {
            let rest = String(host.dropFirst(4))
            if rest.contains(".") { host = rest }
        }
        return host.isEmpty ? nil : host
    }

    /// HTML에서 og:description 우선, 없으면 name="description"을 추출. 없으면 nil.
    static func parseDescription(fromHTML html: String) -> String? {
        if let d = metaContent(in: html, attribute: "property", value: "og:description") { return d }
        if let d = metaContent(in: html, attribute: "name", value: "description") { return d }
        return nil
    }

    /// 속성값(따옴표) 안의 '>'로 인해 태그가 잘리지 않도록 quote-aware하게 <meta ...> 태그를 매칭한다.
    private static let metaTagPattern = "<meta\\b(?:[^>\"']|\"[^\"]*\"|'[^']*')*>"

    private static func metaContent(in html: String, attribute: String, value: String) -> String? {
        let escaped = NSRegularExpression.escapedPattern(for: value)
        let attrPattern = "\\b\(attribute)\\s*=\\s*[\"']\(escaped)[\"']"
        guard let tagRegex = try? NSRegularExpression(pattern: metaTagPattern, options: [.caseInsensitive]),
              let attrRegex = try? NSRegularExpression(pattern: attrPattern, options: [.caseInsensitive]) else { return nil }

        let matches = tagRegex.matches(in: html, range: NSRange(html.startIndex..., in: html))
        for match in matches {
            guard let range = Range(match.range, in: html) else { continue }
            let tag = String(html[range])
            let tagRange = NSRange(tag.startIndex..., in: tag)
            guard attrRegex.firstMatch(in: tag, range: tagRange) != nil else { continue }
            guard let content = contentValue(in: tag) else { continue }
            let decoded = decodeEntities(content).trimmingCharacters(in: .whitespacesAndNewlines)
            return decoded.isEmpty ? nil : decoded
        }
        return nil
    }

    private static func contentValue(in metaTag: String) -> String? {
        let pattern = "content\\s*=\\s*[\"']([^\"']*)[\"']"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: metaTag, range: NSRange(metaTag.startIndex..., in: metaTag)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: metaTag) else { return nil }
        return String(metaTag[range])
    }

    private static func decodeEntities(_ s: String) -> String {
        s.replacingOccurrences(of: "&amp;", with: "&")
         .replacingOccurrences(of: "&lt;", with: "<")
         .replacingOccurrences(of: "&gt;", with: ">")
         .replacingOccurrences(of: "&quot;", with: "\"")
         .replacingOccurrences(of: "&#39;", with: "'")
    }

    /// 노드/리스트 표시용 제목 폴백. 제목이 비면 URL 호스트, 그것도 안 되면 원본 문자열.
    static func displayTitle(title: String, urlString: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        if let host = URL(string: urlString)?.host { return host }
        return urlString
    }
}
