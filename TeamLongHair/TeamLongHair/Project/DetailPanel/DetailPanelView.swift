//
//  DetailPanelView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftUI

struct DetailPanelView: View {
    var body: some View {
        ScrollView{
            VStack{
                LinkView()
                Divider()
                TagView()
                Divider()
                ColorView()
                Divider()
                MemoView()
                Divider()
                CodeBlockView()
            }
        }.frame(width: 300,height: 834)
            .background(Color.bgPrimary)
    }
}

#Preview {
    DetailPanelView()
}
