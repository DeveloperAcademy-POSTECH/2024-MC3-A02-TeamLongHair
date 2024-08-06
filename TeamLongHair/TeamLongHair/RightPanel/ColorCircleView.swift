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
                ZStack {
                    // 상단 왼쪽 흰색 반원
                    Path { path in
                        path.addArc(center: CGPoint(x: 10, y: 10), radius: 10, startAngle: .degrees(135), endAngle: .degrees(-45), clockwise: false)
                    }
                    .fill(Color.white)
                    
                    // 하단 왼쪽 회색 반원
                    Path { path in
                        path.addArc(center: CGPoint(x: 10, y: 10), radius: 10, startAngle: .degrees(-45), endAngle: .degrees(-225), clockwise: false)
                    }
                    .fill(isSelected ? Color.gray : Color(white: 0.8))
                    
                    // 원 외곽선과 대각선
                    Circle()
                        .stroke(Color.black, lineWidth: 1)
                        .frame(width: 20, height: 20)
                    
                    // 대각선이 원안에 있게 조정
                    Path { path in
                        path.move(to: CGPoint(x: 18, y: 2))
                        path.addLine(to: CGPoint(x: 2, y: 18))
                    }
                    .stroke(Color.black, lineWidth: 1)
                    
                    // 호버 및 선택 상태의 외곽선
                    if isHovered || isSelected {
                        Circle()
                            .stroke(Color.gray, lineWidth: 2)
                            .frame(width: 24, height: 24)
                    }
                }
                .frame(width: 20, height: 20)  // Ensure the inner content stays within the circle
                .onHover { hovering in
                    onHover(hovering)
                }
                .onTapGesture {
                    onClick()
                }
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(isHovered ? Color.gray : Color.clear, lineWidth: 2)
                    )
                    .onHover { hovering in
                        onHover(hovering)
                    }
                    .onTapGesture {
                        onClick()
                    }
                
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                        .frame(width: 24, height: 24)
                    
                    Circle()
                        .stroke(color, lineWidth: 1)
                        .frame(width: 26, height: 26)
                    
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .offset(y: -2) // 중앙에 위치하도록 약간 조정
                }
            }
        }
    }
}

//#Preview
struct ColorCircleView_Previews: PreviewProvider {
    static var previews: some View {
        ColorCircleView(color: .blue, isSelected: true, isHovered: false, isGray: false, onHover: { _ in }, onClick: {})
    }
}
