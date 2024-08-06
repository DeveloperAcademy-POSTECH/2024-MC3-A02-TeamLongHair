//
//  CodeBlockView.swift
//  TeamLongHair
//
//  Created by 김준수(엘빈) on 8/2/24.
//

import SwiftUI


struct CodeBlockView: View {
    @State private var textEditorCode: String = ""
    var body: some View {
        VStack{
            HStack {
                Text("Code")
                    .font(
                    Font.custom("Pretendard", size: 16)
                    .weight(.bold)
                    )
                    .foregroundColor(.gray900)
                    .padding(12)
                Spacer()
                Button(action: {
                    
                }  , label: {
                    Image(systemName: "doc.on.doc")
                        .frame(width: 32, height: 32)
                        .padding(6)
                    
                }).buttonStyle(PlainButtonStyle())
            }
            
            TextEditor(text: $textEditorCode)
                .frame(width: 276)
                .frame(minHeight: 108)
                .clipShape(
                    RoundedRectangle(cornerRadius: 5)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(.gray100, lineWidth: 1.5)
                }
                .font(Font.custom("Pretendard", size: 13))
                .colorMultiply(Color("Gray050"))
        }
        .frame(width: 300)
    }
}

#Preview {
    CodeBlockView()
}
