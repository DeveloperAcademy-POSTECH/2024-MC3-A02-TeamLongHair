//
//  ProjectCoverView.swift
//  TeamLongHair
//
//  프로젝트 카드 커버. 링크 파비콘이 있으면 모자이크, 없으면 제목 색조 모노그램.
//

import AppKit
import SwiftUI

struct ProjectCoverView: View {
    let project: Project

    var body: some View {
        // NSImage로 실제 디코드되는 파비콘만 유효로 취급한다.
        let usable = project.mosaicFavicons().filter { NSImage(data: $0) != nil }
        Group {
            if usable.isEmpty {
                MonogramCover(title: project.title)
            } else {
                FaviconMosaic(favicons: usable)
            }
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// 제목 색조 2톤 그라데이션 + 가운데 첫 글자.
struct MonogramCover: View {
    let title: String

    var body: some View {
        let hue = ProjectCardFormatting.stableHue(for: title)
        LinearGradient(
            colors: [Color(hue: hue, saturation: 0.55, brightness: 0.82),
                     Color(hue: hue, saturation: 0.72, brightness: 0.58)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
        .overlay {
            Text(ProjectCardFormatting.monogram(for: title))
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

/// 파비콘 타일 격자. 커버 높이에 맞춰 적응형으로 채우고 넘치면 클립된다.
struct FaviconMosaic: View {
    let favicons: [Data]

    private let columns = [GridItem(.adaptive(minimum: 44, maximum: 56), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(favicons.enumerated()), id: \.offset) { _, data in
                if let image = NSImage(data: data) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8)
                        .aspectRatio(1, contentMode: .fit)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.gray050)
    }
}
