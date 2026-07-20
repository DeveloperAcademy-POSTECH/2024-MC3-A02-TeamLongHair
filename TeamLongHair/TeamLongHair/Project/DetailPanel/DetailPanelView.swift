//
//  DetailPanelView.swift
//  TeamLongHair
//
//  링크 상세 인스펙터. 읽기가 주 목적이라 레이블은 물러나고 내용이 앞에 선다.
//  좌우 인셋은 여기서 한 번만 적용하고, 각 섹션은 자체 좌우 패딩을 두지 않는다.
//

import SwiftUI

struct DetailPanelView: View {
    @Binding var selectedLink: Link?

    var body: some View {
        if let link = selectedLink {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // 캔버스 노드의 탭 표시선과 같은 색 — "이 노드의 상세"임을 잇는다.
                    link.detail.color.accentColor
                        .frame(height: 3)

                    LinkHeaderView(link: link, detail: link.detail)

                    VStack(alignment: .leading, spacing: InspectorMetrics.sectionGap) {
                        LinkDescriptionView(detail: link.detail)
                        MemoView(detail: link.detail)
                        TagView(detail: link.detail)
                        ColorView(detail: link.detail)
                        savedDateRow(link.detail)
                    }
                    .padding(.horizontal, InspectorMetrics.inset)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.bgPrimary)
            .onAppear {
                LinkMetadataApply.fetchAndApply(to: link.detail)
            }
            .onChange(of: link.id) {
                LinkMetadataApply.fetchAndApply(to: link.detail)
            }
        }
    }

    /// 저장 시각은 섹션이 아니라 조용한 한 줄로 맨 아래에 둔다.
    private func savedDateRow(_ detail: LinkDetail) -> some View {
        Text("\(detail.savedDate.formatted(date: .long, time: .shortened)) 저장")
            .font(.system(size: 11))
            .foregroundStyle(.lbQuaternary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
