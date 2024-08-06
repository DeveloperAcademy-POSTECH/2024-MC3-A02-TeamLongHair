//
//  ColorCircleView.swift
//  TeamLongHair
//
//  Created by 김준수(엘빈) on 8/2/24.
//

import SwiftUI

struct ColorCircleView: View {
    var color: Color
    var isSelected: Bool
    var isHovered: Bool
    var isGray: Bool
    var onHover: (Bool) -> Void
    var onClick: () -> Void
    
    var body: some View {
            ZStack {
                       if isGray {
                           Image(isSelected ? "BWSelected" : (isHovered ? "BWFocus" : "Black&White"))
                               .resizable()
                               .frame(width: isSelected || isHovered ? 24 : 20, height: isSelected || isHovered ? 24 : 20)
                               .onHover { hovering in
                                   onHover(hovering)
                               }
                               .onTapGesture {
                                   onClick()
                               }
                       } else {
                           Circle()
                               .fill(color)
                               .frame(width: isSelected || isHovered ? 22 : 20, height: isSelected || isHovered ? 22 : 20)
                               .overlay(
                                   Circle()
                                       .stroke(isHovered ? Color.gray100 : Color.clear, lineWidth: 2)
                               )
                               .onHover { hovering in
                                   onHover(hovering)
                               }
                               .onTapGesture {
                                   onClick()
                               }
                           
                           if isSelected {
                               Circle()
                                   .stroke(Color.white, lineWidth: 2)
                                   .frame(width: 20, height: 20)
                               
                               Circle()
                                   .stroke(color, lineWidth: 2)
                                   .frame(width: 22, height: 22)
                               
                               Image(systemName: "checkmark")
                                   .foregroundColor(.white)
                                   .offset(y: -2) // 중앙에 위치하도록 약간 조정
                           }
                       }
                   }
                   .frame(width: 24, height: 24) // Ensure the overall size stays the same
    }
}

struct ColorCircleView_Previews: PreviewProvider {
    static var previews: some View {
        ColorCircleView(color: .blue, isSelected: true, isHovered: false, isGray: false, onHover: { _ in }, onClick: {})
    }
}

