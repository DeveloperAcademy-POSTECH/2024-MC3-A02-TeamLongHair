//
//  LinkDescriptionView.swift
//  TeamLongHair
//

import SwiftUI

/// 자동 취득한 페이지 설명(읽기 전용). 비어 있으면 아무것도 표시하지 않는다.
struct LinkDescriptionView: View {
    var detail: LinkDetail

    var body: some View {
        if !detail.pageDescription.isEmpty {
            VStack(alignment: .leading, spacing: InspectorMetrics.labelGap) {
                SectionLabel("설명")
                Text(detail.pageDescription)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.lbSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
