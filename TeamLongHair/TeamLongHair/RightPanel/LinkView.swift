//
//  LinkView.swift
//  TeamLongHair
//
//  Created by 김준수(엘빈) on 8/2/24.
//

import SwiftUI

struct LinkView: View {
    @State private var textFieldLink: String = "기본링크"
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "folder.fill")
                    .frame(width: 32, height: 32)
                    .padding(6)
                //아이콘 확정후 변경예정
                Text("PencilKit 공식 문서")
                    .font(
                        Font.custom("Pretendard", size: 16)
                            .weight(.bold)
                    )
                    .foregroundColor(.lbPrimary)
                //데이터 받아오기
                Spacer()
                Button(action: {
                    
                }
                       , label: {
                    Image(systemName: "square.and.arrow.up")
                    
                }).buttonStyle(PlainButtonStyle())
                .frame(width: 32, height: 32)
                    .padding(12)
                
            }
            //아이콘 확정 후 변경예정
            
            
            TextField("", text: $textFieldLink)
                .font(Font.custom("Pretendard", size: 12))
                .overlay {
                               RoundedRectangle(cornerRadius: 5)
                                   .stroke(
                                    Color(.gray100),
                                       lineWidth: 1
                                   )
                           }
                .foregroundColor(.gray900)
                .textFieldStyle(.roundedBorder)
                .padding(8)
            
                
        }.frame(width: 300,height: 118)
        
    }
}

#Preview {
    LinkView()
}
