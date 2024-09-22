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
        VStack(spacing: 18) {
            HStack {
                Text("Memo")
                    .font(Font.custom("Pretendard", size: 14))
                    .foregroundColor(.lbPrimary)

                Spacer()
            }

            TextEditor(text: $desc)
                .frame(minHeight: 108)
                .font(Font.custom("Pretendard", size: 13))
                .foregroundStyle(.lbSecondary)
                .padding(12)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray100, lineWidth: 1)
                }
        }
        .padding(.horizontal, 16)
        .frame(width: 300)
        .onChange(of: detail) {
            desc = detail.desc
        }
        .onChange(of: desc) {
            detail.desc = desc
        }
    }
}
