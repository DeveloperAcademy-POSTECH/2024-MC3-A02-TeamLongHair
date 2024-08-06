//
//  RightPanelView.swift
//  TeamLongHair
//
//  Created by 김준수(엘빈) on 8/2/24.
//

import SwiftUI

struct RightPanelView: View {
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
    RightPanelView()
}
