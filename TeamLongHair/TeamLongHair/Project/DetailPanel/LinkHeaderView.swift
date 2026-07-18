//
//  LinkHeaderView.swift
//  TeamLongHair
//

import AppKit
import SwiftUI

struct LinkHeaderView: View {
    var link: Link
    var detail: LinkDetail

    private var domain: String {
        LinkMetadataParsing.normalizedURL(from: detail.URL)?.host ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 썸네일 배너(없으면 파비콘 큰 아이콘)
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(.bgSecondary)
                if let data = detail.thumbnailData, let img = NSImage(data: data) {
                    Image(nsImage: img)
                        .resizable().scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if let fav = detail.faviconData, let img = NSImage(data: fav) {
                    Image(nsImage: img).resizable().aspectRatio(contentMode: .fit).frame(width: 44, height: 44)
                } else {
                    Image(systemName: "globe").font(.system(size: 36)).foregroundStyle(.lbTertiary)
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .clipped()

            HStack(spacing: 8) {
                if let fav = detail.faviconData, let img = NSImage(data: fav) {
                    Image(nsImage: img).resizable().aspectRatio(contentMode: .fit).frame(width: 18, height: 18)
                }
                TextField("제목", text: Binding(get: { detail.title }, set: { detail.title = $0 }))
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.lbPrimary)
            }

            if !domain.isEmpty {
                Text(domain).font(.system(size: 12)).foregroundStyle(.lbTertiary)
            }

            HStack(spacing: 8) {
                Button { link.openInBrowser() } label: { Label("열기", systemImage: "safari") }
                Button {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(detail.URL, forType: .string)
                } label: { Label("URL 복사", systemImage: "doc.on.doc") }
                Spacer()
                Button { LinkMetadataApply.fetchAndApply(to: detail, force: true) } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("메타데이터 새로고침")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(LinkMetadataParsing.normalizedURL(from: detail.URL) == nil)
        }
        .padding(12)
    }
}
