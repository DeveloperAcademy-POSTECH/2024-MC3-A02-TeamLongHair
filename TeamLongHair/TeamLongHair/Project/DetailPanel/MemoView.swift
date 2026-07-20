//
//  MemoView.swift
//  TeamLongHair
//

import SwiftUI

/// 사용자가 직접 쓰는 메모. Enter로 줄바꿈되고, 내용에 따라 높이가 자란다.
/// 비어 있으면 안내 문구를 보여준다.
struct MemoView: View {
    var detail: LinkDetail

    private let font = Font.system(size: 12.5)
    private let minHeight: CGFloat = 62
    /// TextEditor는 안쪽에 약 5pt 여백이 있어, 측정용 Text와 글자 시작점을 맞추려면
    /// 바깥 패딩을 그만큼 줄여야 두 높이가 어긋나지 않는다.
    private let textInset: CGFloat = 10
    private let editorInset: CGFloat = 5

    var body: some View {
        VStack(alignment: .leading, spacing: InspectorMetrics.labelGap) {
            SectionLabel("메모")

            ZStack(alignment: .topLeading) {
                // TextEditor는 자기 내용 높이를 알려주지 않는다.
                // 같은 글자를 투명하게 깔아 컨테이너 높이를 내용만큼 늘린다.
                Text(detail.desc.isEmpty ? " " : detail.desc)
                    .font(font)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, textInset)
                    .padding(.vertical, 8)
                    .opacity(0)
                    .accessibilityHidden(true)

                if detail.desc.isEmpty {
                    Text("생각나는 걸 적어두세요")
                        .font(font)
                        .foregroundStyle(.lbQuaternary)
                        .padding(.horizontal, textInset)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }

                TextEditor(text: Binding(get: { detail.desc }, set: { detail.desc = $0 }))
                    .font(font)
                    .foregroundStyle(.lbPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, editorInset)
                    .padding(.vertical, 7)
            }
            .frame(minHeight: minHeight, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 8).fill(.bgPrimary))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray100, lineWidth: 1))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
