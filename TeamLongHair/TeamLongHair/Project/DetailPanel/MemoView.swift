//
//  MemoView.swift
//  TeamLongHair
//

import SwiftUI

/// 사용자가 직접 쓰는 메모. 내용에 따라 높이가 자라고, 비어 있으면 안내 문구를 보여준다.
struct MemoView: View {
    var detail: LinkDetail

    var body: some View {
        VStack(alignment: .leading, spacing: InspectorMetrics.labelGap) {
            SectionLabel("메모")

            TextField(
                "생각나는 걸 적어두세요",
                text: Binding(get: { detail.desc }, set: { detail.desc = $0 }),
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .lineLimit(3...10)
            .font(.system(size: 12.5))
            .foregroundStyle(.lbPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(.bgPrimary))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray100, lineWidth: 1))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
