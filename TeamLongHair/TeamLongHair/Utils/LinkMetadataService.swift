//
//  LinkMetadataService.swift
//  TeamLongHair
//
//  URL에서 제목·파비콘·썸네일(LinkPresentation)과 설명(HTML 파싱)을 베스트-에포트로 취득.
//  모든 실패는 해당 필드 nil로 폴백한다(throw 없음).
//

import AppKit
import LinkPresentation

struct FetchedLinkMetadata {
    var title: String?
    var faviconData: Data?
    var thumbnailData: Data?
    var description: String?
}

enum LinkMetadataService {
    /// 무효 URL이면 nil. 그 외에는 취득 가능한 필드만 채운 구조체를 반환.
    static func fetch(urlString: String) async -> FetchedLinkMetadata? {
        guard let url = LinkMetadataParsing.normalizedURL(from: urlString) else { return nil }

        async let lp = fetchLinkPresentation(url)
        async let desc = fetchDescription(url)
        let (lpResult, description) = await (lp, desc)

        return FetchedLinkMetadata(
            title: lpResult.title,
            faviconData: lpResult.favicon,
            thumbnailData: lpResult.thumbnail,
            description: description
        )
    }

    private static func fetchLinkPresentation(_ url: URL) async
        -> (title: String?, favicon: Data?, thumbnail: Data?) {
        let metadata: LPLinkMetadata? = await withCheckedContinuation { continuation in
            let provider = LPMetadataProvider()
            provider.startFetchingMetadata(for: url) { metadata, _ in
                continuation.resume(returning: metadata)
            }
        }
        guard let metadata else { return (nil, nil, nil) }
        let favicon = await imageData(from: metadata.iconProvider)
        let thumbnail = await imageData(from: metadata.imageProvider)
        return (metadata.title, favicon, thumbnail)
    }

    private static func imageData(from provider: NSItemProvider?) async -> Data? {
        guard let provider else { return nil }
        return await withCheckedContinuation { continuation in
            _ = provider.loadObject(ofClass: NSImage.self) { object, _ in
                guard let image = object as? NSImage,
                      let tiff = image.tiffRepresentation,
                      let rep = NSBitmapImageRep(data: tiff),
                      let png = rep.representation(using: .png, properties: [:]) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: png)
            }
        }
    }

    private static func fetchDescription(_ url: URL) async -> String? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1)
        else { return nil }
        return LinkMetadataParsing.parseDescription(fromHTML: html)
    }
}
