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
                LinkView(link: link, detail: link.detail)

                Divider()

                TagView(detail: link.detail)
                
                Divider()
                
                ColorView(detail: link.detail)

                Divider()

                MemoView(detail: link.detail)
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
