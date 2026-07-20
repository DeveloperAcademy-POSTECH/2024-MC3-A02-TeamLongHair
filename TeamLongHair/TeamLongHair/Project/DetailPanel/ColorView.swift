//
//  ColorView.swift
//  TeamLongHair
//

import SwiftUI

/// 노드 색 선택. 여기서 고른 색이 캔버스 노드의 탭 표시선과 이 패널 상단 띠에 쓰인다.
struct ColorView: View {
    var detail: LinkDetail

    var body: some View {
        VStack(alignment: .leading, spacing: InspectorMetrics.labelGap) {
            SectionLabel("색")

            HStack(spacing: 9) {
                ForEach(IconColor.allCases, id: \.self) { iconColor in
                    ColorCircleView(
                        color: iconColor.returnColor(),
                        isSelected: iconColor == detail.color,
                        isGray: iconColor == .gray,   // 회색인 경우 이미지를 사용
                        onClick: { detail.color = iconColor }
                    )
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
