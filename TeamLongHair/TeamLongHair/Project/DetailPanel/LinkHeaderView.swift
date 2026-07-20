//
//  LinkHeaderView.swift
//  TeamLongHair
//

import AppKit
import SwiftUI

struct LinkHeaderView: View {
    var link: Link
    var detail: LinkDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 썸네일 배너(없으면 파비콘, 그것도 없으면 글로브)
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(.bgSecondary)
                if let data = detail.thumbnailData, let img = NSImage(data: data) {
                    Image(nsImage: img)
                        .resizable().scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                } else if let fav = detail.faviconData, let img = NSImage(data: fav) {
                    Image(nsImage: img).resizable().aspectRatio(contentMode: .fit).frame(width: 44, height: 44)
                } else {
                    Image(systemName: "globe").font(.system(size: 34)).foregroundStyle(.lbTertiary)
                }
            }
            .frame(height: 116)
            .frame(maxWidth: .infinity)
            .clipped()

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    if let fav = detail.faviconData, let img = NSImage(data: fav) {
                        Image(nsImage: img).resizable().aspectRatio(contentMode: .fit).frame(width: 17, height: 17)
                    }
                    TextField("제목", text: Binding(get: { detail.title }, set: { detail.title = $0 }))
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.lbPrimary)
                }

                if !detail.displayDomain.isEmpty {
                    Text(detail.displayDomain)
                        .font(.system(size: 11.5))
                        .foregroundStyle(.lbTertiary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    Button { link.openInBrowser() } label: { Label("열기", systemImage: "safari") }
                    Button {
                        let pb = NSPasteboard.general
                        pb.clearContents()
                        pb.setString(detail.URL, forType: .string)
                    } label: { Label("URL 복사", systemImage: "doc.on.doc") }
                    Spacer(minLength: 0)
                    Button { LinkMetadataApply.fetchAndApply(to: detail, force: true) } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("메타데이터 새로고침")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(LinkMetadataParsing.normalizedURL(from: detail.URL) == nil)
                .padding(.top, 3)
            }
        }
        .padding(.horizontal, InspectorMetrics.inset)
        .padding(.top, InspectorMetrics.inset)
    }
}
