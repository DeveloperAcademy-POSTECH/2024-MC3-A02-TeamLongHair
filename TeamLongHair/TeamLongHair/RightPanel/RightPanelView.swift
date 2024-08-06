//
//  RightPanelView.swift
//  TeamLongHair
//
//  Created by 김준수(엘빈) on 8/2/24.
//

import SwiftUI

struct RightPanelView: View {
    @State private var selectedColorIndex: IconColor? = nil
    
    var colors: [Color] = [
        .gray,
        Color("node_red"),
        Color("node_orange"),
        Color("node_yellow"),
        Color("node_green"),
        Color("node_sky"),
        Color("node_blue"),
        Color("node_purple"),
        Color("node_plum")
    ]
    
    var body: some View {
        ScrollView{
            VStack{
                LinkView(selectedColorIndex: $selectedColorIndex, colors: colors)
                Divider()
                TagView()
                Divider()
                ColorView(selectedColorIndex: $selectedColorIndex, colors: colors)
                Divider()
                MemoView()
                Divider()
                CodeBlockView()
            }
        }
        .frame(width: 300, height: 834)
        .background(Color.bgPrimary)
    }
}

struct RightPanelView_Previews: PreviewProvider {
    static var previews: some View {
        RightPanelView()
    }
}
