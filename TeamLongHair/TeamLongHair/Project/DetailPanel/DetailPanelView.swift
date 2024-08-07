//
//  DetailPanelView.swift
//  TeamLongHair
//
//  Created by 김준수(엘빈) on 8/2/24.
//

import SwiftUI

struct DetailPanelView: View {
    @State private var selectedColorIndex: IconColor? = nil
    @Binding var selectedLink: Link?
    
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
        if let link = selectedLink {
            ScrollView {
                LinkView(selectedLink: $selectedLink)
                
                Divider()
                
                TagView()
                
                Divider()
                
                ColorView(selectedColorIndex: $selectedColorIndex, colors: colors)
                
                Divider()
                
                MemoView(textEditorMemo: link.detail.desc)
                
                Divider()
                
                CodeBlockView(textEditorCode: link.detail.code)
            }
            .frame(width: 300)
            .background(Color.bgPrimary)
        }
    }
}

//struct RightPanelView_Previews: PreviewProvider {
//    static var previews: some View {
//        DetailPanelView()
//    }
//}
