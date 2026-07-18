//
//  MemoView.swift
//  TeamLongHair
//
//  Created by 김준수(엘빈) on 8/2/24.
//

import SwiftUI

struct MemoView: View {
    var detail: LinkDetail

    var body: some View {
        VStack {
            Text("Memo")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(
                    Font.custom("Pretendard", size: 16)
                        .weight(.bold)
                )
            
                TextEditor(text: Binding(get: { detail.desc }, set: { detail.desc = $0 }))
                    .foregroundStyle(.lbPrimary)
                    .frame(maxWidth: .infinity, minHeight: 108)
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
        .frame(maxWidth: .infinity)
        .padding(11)
    }
}

//#Preview {
//    MemoView()
//}
