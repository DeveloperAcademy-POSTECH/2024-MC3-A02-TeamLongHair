//
//  ColorView.swift
//  TeamLongHair
//
//  Created by 김준수(엘빈) on 8/2/24.
//

import SwiftUI

struct ColorView: View {
    @Binding var selectedColorIndex: IconColor?
    let colors: [Color]
    @State private var hoveredIndex: Int? = nil
    
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
                ForEach(colors.indices, id: \.self) { index in
                    ColorCircleView(
                        color: colors[index],
                        isSelected: selectedColorIndex == IconColor.allCases[index],
                        isHovered: hoveredIndex == index,
                        isGray: index == 0, // 회색인 경우 이미지를 사용
                        onHover: { hovering in
                            if hovering {
                                hoveredIndex = index
                            } else if hoveredIndex == index {
                                hoveredIndex = nil
                            }
                        },
                        onClick: {
                            selectedColorIndex = IconColor.allCases[index]
                        }
                    )
                }
            }
            .padding()
        }
        .frame(width: 300)
    }
}

struct ColorView_Previews: PreviewProvider {
    static var previews: some View {
        ColorView(selectedColorIndex: .constant(.gray), colors: [])
    }
}
