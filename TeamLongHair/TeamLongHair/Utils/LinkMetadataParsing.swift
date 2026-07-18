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

    /// HTML에서 og:description 우선, 없으면 name="description"을 추출. 없으면 nil.
    static func parseDescription(fromHTML html: String) -> String? {
        if let d = metaContent(in: html, attribute: "property", value: "og:description") { return d }
        if let d = metaContent(in: html, attribute: "name", value: "description") { return d }
        return nil
    }

    private static func metaContent(in html: String, attribute: String, value: String) -> String? {
        let escaped = NSRegularExpression.escapedPattern(for: value)
        let pattern = "<meta[^>]*\\b\(attribute)\\s*=\\s*[\"']\(escaped)[\"'][^>]*>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range, in: html) else { return nil }
        let tag = String(html[range])
        guard let content = contentValue(in: tag) else { return nil }
        let decoded = decodeEntities(content).trimmingCharacters(in: .whitespacesAndNewlines)
        return decoded.isEmpty ? nil : decoded
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
}
