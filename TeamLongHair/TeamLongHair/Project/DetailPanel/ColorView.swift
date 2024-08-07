//
//  ColorView.swift
//  TeamLongHair
//
//  Created by 김준수(엘빈) on 8/2/24.
//

import SwiftUI

struct ColorView: View {
    var detail: LinkDetail
    
    var body: some View {
        VStack {
            Text("Color")
                .font(
                    Font.custom("Pretendard", size: 16)
                        .weight(.bold)
                )
                .foregroundColor(.lbPrimary)
                .padding(12)
                .frame(width: 300, alignment: .leading)
            HStack {
                ForEach(IconColor.allCases, id: \.self) { iconColor in
                    ColorCircleView(
                        color: iconColor.returnColor(),
                        isSelected: detail.color == iconColor,
                        isGray: iconColor == IconColor.gray, // 회색인 경우 이미지를 사용
                        onClick: {
                            detail.color = iconColor
                        }
                    )
                }
            }
            .padding()
        }
        .frame(width: 300)
    }
}
