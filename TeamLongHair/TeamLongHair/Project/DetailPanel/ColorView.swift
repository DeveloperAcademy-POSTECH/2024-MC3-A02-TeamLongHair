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
        VStack(spacing: 10) {
            HStack {
                Text("Color")
                    .font(Font.custom("Pretendard", size: 14))
                    .foregroundColor(.lbPrimary)

                Spacer()
            }
            
            HStack(spacing: 7) {
                ForEach(IconColor.allCases, id: \.self) { iconColor in
                    if iconColor == detail.color {
                        ColorCircleView(
                            color: iconColor.returnColor(),
                            isSelected: true,
                            isGray: iconColor == IconColor.gray, // 회색인 경우 이미지를 사용
                            onClick: {
                                detail.color = iconColor
                            }
                        )
                    } else {
                        ColorCircleView(
                            color: iconColor.returnColor(),
                            isSelected: false,
                            isGray: iconColor == IconColor.gray, // 회색인 경우 이미지를 사용
                            onClick: {
                                detail.color = iconColor
                            }
                        )
                    }
                }
            }
            .padding(.vertical, 10)
        }
        .padding(.horizontal, 16)
        .frame(width: 300)
    }
}
