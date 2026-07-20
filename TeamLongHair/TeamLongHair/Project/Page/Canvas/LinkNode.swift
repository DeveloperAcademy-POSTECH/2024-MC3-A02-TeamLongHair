//
//  LinkNode.swift
//  TeamLongHair
//
//  캔버스 노드를 "브라우저 탭"으로 도식화: 탭 바(파비콘+제목+×) / 주소창(도메인) / 본문(설명+태그).
//  색(IconColor)은 탭 활성 표시선으로만 드러낸다.
//

import AppKit
import SwiftUI

struct LinkNode: View {
    var link: Link
    var sizeOfNode: CGFloat = CanvasMetrics.nodeWidth
    var isSelected: Bool
    /// 드래그로 연결하려는 대상(부모 후보)일 때 강조 표시.
    var isDropTarget: Bool = false

    private var s: CGFloat { sizeOfNode / CanvasMetrics.nodeWidth }
    private var accent: Color {
        link.detail.color == .gray ? Color.gray300 : link.detail.color.returnColor()
    }

    var body: some View {
        let domain = link.detail.displayDomain
        return VStack(alignment: .leading, spacing: 0) {
            tabBar
            if !domain.isEmpty {
                addressBar(domain)
            }
            bodyArea
            Spacer(minLength: 0)
        }
        .frame(width: sizeOfNode, height: CanvasMetrics.nodeHeight * s, alignment: .topLeading)
        .background(.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 11 * s))
        .overlay {
            RoundedRectangle(cornerRadius: 11 * s).stroke(Color.gray100, lineWidth: 1 * s)
        }
        .contentShape(Rectangle())
        // 선택 강조: 파랑 글로우
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 11 * s).stroke(Color.blue400, lineWidth: 3.5 * s)
            }
        }
        // 드롭 대상 강조: 보라 글로우(드래그 중, 선택보다 위)
        .overlay {
            if isDropTarget {
                RoundedRectangle(cornerRadius: 11 * s).stroke(Color.purple400, lineWidth: 4 * s)
            }
        }
        .shadow(color: isDropTarget ? Color.purple400.opacity(0.6)
                    : (isSelected ? Color.blue400.opacity(0.55) : Color.black.opacity(0.10)),
                radius: (isDropTarget || isSelected) ? 10 : 6, x: 0, y: 4)
        .scaleEffect(isDropTarget ? 1.04 : 1.0)
        .animation(.easeOut(duration: 0.12), value: isDropTarget)
        .animation(.easeOut(duration: 0.12), value: isSelected)
    }

    // MARK: - 탭 바 (활성 표시선 + 파비콘 + 제목 + ×)
    private var tabBar: some View {
        VStack(spacing: 0) {
            accent.frame(height: 2.5 * s)
            HStack(spacing: 6 * s) {
                favicon.frame(width: 15 * s, height: 15 * s)
                Text(link.detail.displayTitle)
                    .font(.system(size: 14 * s, weight: .semibold))
                    .foregroundStyle(.lbPrimary)
                    .lineLimit(1)
                Spacer(minLength: 4 * s)
                Image(systemName: "xmark")
                    .font(.system(size: 9 * s, weight: .semibold))
                    .foregroundStyle(.lbQuaternary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 10 * s)
            .padding(.vertical, 6 * s)
            .background(.bgPrimary)
        }
        // 탭이 바 폭을 채우게 하여 긴 제목이 카드를 넘지 않고 말줄임되도록 한다.
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 9 * s, topTrailingRadius: 9 * s))
        .padding(.top, 5 * s)
        .padding(.horizontal, 6 * s)
        .background(.gray050)
    }

    // MARK: - 주소창 (도메인)
    private func addressBar(_ domain: String) -> some View {
        HStack(spacing: 5 * s) {
            Image(systemName: "lock.fill")
                .font(.system(size: 8 * s))
                .foregroundStyle(.lbTertiary)
                .accessibilityHidden(true)
            Text(domain)
                .font(.system(size: 11 * s))
                .foregroundStyle(.lbTertiary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8 * s)
        .padding(.vertical, 4 * s)
        .background(RoundedRectangle(cornerRadius: 6 * s).fill(.gray050))
        .padding(.horizontal, 10 * s)
        .padding(.top, 5 * s)
    }

    // MARK: - 본문 (설명 + 태그)
    private var bodyArea: some View {
        VStack(alignment: .leading, spacing: 4 * s) {
            if !link.detail.pageDescription.isEmpty {
                Text(link.detail.pageDescription)
                    .font(.system(size: 11 * s))
                    .foregroundStyle(.lbTertiary)
                    .lineLimit(2)
            }
            if !link.detail.tags.isEmpty {
                HStack(spacing: 4 * s) {
                    ForEach(link.detail.tags.prefix(3), id: \.self) { tag in
                        tagChip(tag)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12 * s)
        .padding(.top, 4 * s)
        .padding(.bottom, 6 * s)
    }

    // MARK: - 조각
    private var favicon: some View {
        Group {
            if let data = link.detail.faviconData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage).resizable().aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "globe").resizable().foregroundStyle(.lbTertiary)
            }
        }
    }

    private func tagChip(_ tag: String) -> some View {
        Text(tag)
            .lineLimit(1)
            .font(.system(size: 10 * s))
            .foregroundStyle(.lbTertiary)
            .padding(.horizontal, 7 * s)
            .padding(.vertical, 2 * s)
            .background(RoundedRectangle(cornerRadius: 5 * s).fill(.gray050))
    }
}

#Preview {
    VStack(spacing: 16) {
        // 기본색(.gray) + 도메인/설명/태그 모두 있음 — 높이 예산이 가장 빡빡한 경우
        LinkNode(link: {
            let d = LinkDetail(URL: "https://developer.apple.com/documentation/swift", title: "스위프트 공식 문서 아주 긴 제목 예시")
            d.pageDescription = "스위프트를 배우는 애플 공식 문서. 언어 가이드와 표준 라이브러리 레퍼런스를 제공합니다."
            d.tags = ["swift", "ios", "docs"]
            return Link(detail: d)
        }(), isSelected: false)

        // 도메인 없음 + 설명 없음
        LinkNode(link: .init(detail: .init(URL: "", title: "메모 노드")), isSelected: false)

        // 선택 상태
        LinkNode(link: .init(detail: .init(URL: "https://github.com", title: "깃허브")), isSelected: true)
    }
    .padding()
}
