//
//  FloatingPanelView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftUI

struct FloatingPanelView: View {
    @State private var panelTitleText = ""
    @State private var panelURLText = ""
    
    var sidebarWidth: CGFloat = 256.0
    var totalWidth: CGFloat = 700.0
    var minHeight: CGFloat = 512.0
        
    var body: some View {        
        GeometryReader { geo in
            ZStack {
                VisualEffectView()
                
                VStack(spacing: 0) {
                    RoundedTextField(text: .constant(""), placeholder: "URL을 입력해 주세요", cornerRadius: 8)
                        .foregroundStyle(Color.gray050)
                    RoundedTextField(text: .constant(""), placeholder: "제목을 입력해 주세요", cornerRadius: 8)
                        .foregroundStyle(Color.gray050)
                    
                    Spacer()
                    
                    
                    HStack(spacing: 0) {
                        VStack {
                            Spacer()
                            Text("ProjectList")
                            Divider()

                            Spacer()
                        }
                        .background(Color.blue)
                        .frame(minWidth: sidebarWidth, maxWidth: totalWidth)

                        
                        VStack(spacing: 0) {
                            Text("PageList")
                                .frame(width: geo.size.width - sidebarWidth)
                        }
                        .background(Color.yellow)
                        .transition(.move(edge: .trailing))
                    }
                }
                .padding(16)
            }
        }
        .frame(minWidth: sidebarWidth, minHeight: minHeight)
    }
}


struct RoundedTextField: View {
    @Binding var text: String
    var placeholder: String = ""
    var cornerRadius: CGFloat = 10.0
    var textColor: Color = Color.gray050
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(PlainTextFieldStyle())
            .padding(.horizontal) // 텍스트 필드의 패딩
            .padding(.vertical, 13)
            .background(Color.gray050)
            .foregroundColor(Color.lbQuaternary) // 텍스트 색상
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.lbQuaternary, lineWidth: 1) // 둥근 테두리 추가
            )
            .cornerRadius(cornerRadius) // 둥근 모서리)
    }
}

#Preview {
    FloatingPanelView()
        .environment(AppState.shared)
}
