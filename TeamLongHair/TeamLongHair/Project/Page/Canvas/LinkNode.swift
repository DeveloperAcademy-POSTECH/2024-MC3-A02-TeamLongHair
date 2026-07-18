//
//  LinkNode.swift
//  TeamLongHair
//
//  Created by Lee Sihyeong on 8/4/24.
//

import AppKit
import SwiftUI

struct LinkNode: View {
    var link: Link
    var sizeOfNode: CGFloat = CanvasMetrics.nodeWidth
    var isSelected: Bool
    /// 드래그로 연결하려는 대상(부모 후보)일 때 강조 표시.
    var isDropTarget: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: 8 * (sizeOfNode / 244))
            .stroke(style: StrokeStyle(lineWidth: isSelected ? 3 * (sizeOfNode / 244) : 1 * (sizeOfNode / 244)))
            .foregroundStyle(link.detail.color.returnColor())
            .frame(width: sizeOfNode, height: 118 * (sizeOfNode / 244))
            .overlay {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Group {
                            if let data = link.detail.faviconData, let nsImage = NSImage(data: data) {
                                Image(nsImage: nsImage).resizable().aspectRatio(contentMode: .fit)
                            } else {
                                Image(systemName: "globe")
                                    .resizable()
                                    .foregroundStyle(link.detail.color.returnColor())
                            }
                        }
                        .frame(width: 20 * (sizeOfNode / 244), height: 20 * (sizeOfNode / 244))
                        Text(link.detail.displayTitle)
                            .font(.system(size: 16 * (sizeOfNode / 244), weight: .medium))
                            .padding(.top, 4 * (sizeOfNode / 244))
                            .padding(.bottom, 12 * (sizeOfNode / 244))
                        HStack(spacing: 4 * (sizeOfNode / 244)) {
                            ForEach(link.detail.tags, id: \.self) { tag in
                                tagView(tag: tag)
                            }
                        }
                        .frame(height: 24 * (sizeOfNode / 244))
                    }
                    .padding(.leading, 16 * (sizeOfNode / 244))
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .background {
                Color.bgPrimary
                    .shadow(color: link.detail.color.returnColor().opacity(isSelected ? 0.2 : 0.1), radius: 6, x: 0, y: 4)
            }
            // 선택 강조: 파랑 글로우 테두리(지속)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8 * (sizeOfNode / 244))
                        .stroke(Color.blue400, lineWidth: 3.5 * (sizeOfNode / 244))
                }
            }
            // 드롭 대상 강조: 굵은 보라 테두리(드래그 중, 선택보다 위)
            .overlay {
                if isDropTarget {
                    RoundedRectangle(cornerRadius: 8 * (sizeOfNode / 244))
                        .stroke(Color.purple400, lineWidth: 4 * (sizeOfNode / 244))
                }
            }
            .shadow(color: isDropTarget ? Color.purple400.opacity(0.6)
                        : (isSelected ? Color.blue400.opacity(0.55) : .clear),
                    radius: (isDropTarget || isSelected) ? 10 : 0)
            .scaleEffect(isDropTarget ? 1.04 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isDropTarget)
            .animation(.easeOut(duration: 0.12), value: isSelected)
    }
    
    @ViewBuilder
    func tagView(tag: String) -> some View {
        RoundedRectangle(cornerRadius: 4 * (sizeOfNode / 244))
            .stroke()
            .foregroundStyle(.gray100)
            .frame(width: 68 * (sizeOfNode / 244), height: 24 * (sizeOfNode / 244))
            .background(.bgPrimary)
            .overlay {
                Text(tag)
                    .font(.system(size: 12 * (sizeOfNode / 244), weight: .regular))
            }
    }
}

#Preview {
    LinkNode(link: .init(detail: .init(URL: "", title: "2")), isSelected: true)
}
