//
//  ColorView.swift
//  TeamLongHair
//
//  Created by 김준수(엘빈) on 8/2/24.
//

import SwiftUI

struct ColorView: View {
    @State private var hoveredIndex: Int? = nil
    @State private var selectedIndex: Int? = nil
    
    let colors: [Color?] = [ nil,
                             Color(red: 1.0, green: 0.38, blue: 0.38), // FF6262
                             Color(red: 1.0, green: 0.58, blue: 0.18), // FF932E
                             Color(red: 0.99, green: 0.82, blue: 0.03), // FCD307
                             Color(red: 0.30, green: 0.75, blue: 0.59), // 4CBF96
                             Color(red: 0.33, green: 0.86, blue: 0.98), // 53DCFA
                             Color(red: 0.25, green: 0.54, blue: 0.93), // 408AEC
                             Color(red: 0.43, green: 0.45, blue: 0.97), // 6D72F9
                             Color(red: 0.74, green: 0.18, blue: 0.82)  // BC2DD1
    ]
       
    var body: some View {
        VStack{
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
                        color: colors[index] ?? .clear,
                        isSelected: selectedIndex == index,
                        isHovered: hoveredIndex == index,
                        isGray: colors[index] == nil,
                        onHover: { hovering in
                            if hovering {
                                hoveredIndex = index
                            } else if hoveredIndex == index {
                                hoveredIndex = nil
                            }
                        },
                        onClick: {
                            selectedIndex = index
                        }
                    )
                }
            }.frame(width: 300)
            .padding()
           
        }.frame(width: 300)
    }
}

#Preview {
    ColorView()
}
