//
//  InspectorStyle.swift
//  TeamLongHair
//
//  상세 패널의 공통 규칙: 섹션 레이블, 간격, 노드와 공유하는 액센트 색.
//  각 섹션 뷰는 자체 좌우 패딩을 두지 않는다 — 인셋은 DetailPanelView가 한 번만 적용한다.
//  (frame(maxWidth:.infinity) 뒤에 padding()을 붙이면 컨테이너보다 넓어져 잘린다.)
//

import SwiftUI

enum InspectorMetrics {
    /// 패널 좌우 인셋(한 곳에서만 적용).
    static let inset: CGFloat = 16
    /// 섹션과 섹션 사이.
    static let sectionGap: CGFloat = 20
    /// 레이블과 그 내용 사이.
    static let labelGap: CGFloat = 6
}

/// 섹션 레이블. 작고 조용하게 — 내용이 주인공이 되도록 물러난다.
struct SectionLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .kerning(0.4)
            .foregroundStyle(.lbTertiary)
    }
}

extension IconColor {
    /// 캔버스 노드의 탭 표시선과 상세 패널 상단 띠가 공유하는 색.
    /// 기본값(gray)은 밝은 배경에 묻히므로 진한 중립으로 올린다.
    var accentColor: Color {
        self == .gray ? .gray300 : returnColor()
    }
}
