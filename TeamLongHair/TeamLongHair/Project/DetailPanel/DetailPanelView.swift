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
    
    var body: some View {
        if let link = selectedLink {
            ScrollView {
                LinkView(detail: link.detail)
                
                Divider()
                
                // TODO: 얘 좀 이상함;
                TagView(detail: link.detail)
                
                Divider()
                
                ColorView(detail: link.detail)
                
                Divider()
                
                MemoView(detail: link.detail)
                
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
