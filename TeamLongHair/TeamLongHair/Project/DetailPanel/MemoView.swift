//
//  MemoView.swift
//  TeamLongHair
//
//  Created by 김준수(엘빈) on 8/2/24.
//

import SwiftUI

struct MemoView: View {
    @State var desc: String = ""
    var detail: LinkDetail
    
    var body: some View {
        VStack {
            Text("Memo")
                .frame(width: 276, alignment: .leading)
                .font(
                    Font.custom("Pretendard", size: 16)
                        .weight(.bold)
                )
            
                TextEditor(text: $desc)
                    .foregroundStyle(.lbPrimary)
                    .frame(width: 276, height: 108)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 5)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color("Gray100"), lineWidth: 1.5)
                    }
                    .font(Font.custom("Pretendard", size: 13))
                    .colorMultiply(.gray050)
            
        }
        .frame(width: 300)
        .padding(11)
        .onChange(of: detail) {
            desc = detail.desc
        }
        .onChange(of: desc) {
            detail.desc = desc
        }
    }
}

//#Preview {
//    MemoView()
//}
