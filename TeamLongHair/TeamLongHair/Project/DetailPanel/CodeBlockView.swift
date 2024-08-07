//
//  CodeBlockView.swift
//  TeamLongHair
//
//  Created by 김준수(엘빈) on 8/2/24.
//
import SwiftUI
import AppKit

struct CodeBlockView: View {
    @State private var textEditorCode: String = ""
    @State private var showToast: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Code")
                    .font(
                        Font.custom("Pretendard", size: 16)
                            .weight(.bold)
                    )
                    .foregroundColor(Color("Gray900"))
                    .padding(12)
                Spacer()
                Button(action: {
                    copyToClipboard()
                    showToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showToast = false
                    }
                }, label: {
                    Image(systemName: "doc.on.doc")
                        .frame(width: 32, height: 32)
                        .padding(6)
                })
                .buttonStyle(PlainButtonStyle())
            }
            
            TextEditor(text: $textEditorCode)
                .frame(width: 276)
                .frame(minHeight: 108)
                .clipShape(
                    RoundedRectangle(cornerRadius: 5)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color("Gray100"), lineWidth: 1.5)
                }
                .font(Font.custom("Pretendard", size: 13))
                .colorMultiply(Color("Gray050"))
        }
        .frame(width: 300)
        .overlay(
            VStack {
                if showToast {
                    Text("복사되었습니다")
                        .font(Font.custom("Pretendard", size: 13))
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .transition(.opacity)
                }
                Spacer()
            }
        )
        .animation(.easeInOut, value: showToast)
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(textEditorCode, forType: .string)
    }
}

#Preview {
    CodeBlockView()
}
