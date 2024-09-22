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
                
                dividerView
                
                // TODO: 얘 좀 이상함;
                TagView(detail: link.detail)
                
                dividerView
                
                // TODO: 얘 좀 이상함;
                ColorView(detail: link.detail)
                
                dividerView
                
                MemoView(detail: link.detail)
                
                dividerView
                
                CodeBlockView(detail: link.detail)
            }
            .frame(width: 300)
            .background(Color.bgPrimary)
        }
    }
    
    private var dividerView: some View {
        Divider()
            .padding(.bottom, 10)
    }
}

//struct RightPanelView_Previews: PreviewProvider {
//    static var previews: some View {
//        DetailPanelView()
//    }
//}
