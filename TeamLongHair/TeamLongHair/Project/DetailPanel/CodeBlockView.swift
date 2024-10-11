//
//  CodeBlockView.swift
//  TeamLongHair
//
//  Created by 김준수(엘빈) on 8/2/24.
//
import SwiftUI
import AppKit

struct CodeBlockView: View {
    @State private var showToast: Bool = false
    @State var code: String = ""
    
    var detail: LinkDetail
    
    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("Code")
                    .font(Font.custom("Pretendard", size: 14))
                    .foregroundColor(.lbPrimary)
                
                Spacer()
                
                Button {
                    copyToClipboard()
                    showToast = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showToast = false
                    }
                } label: {
                    Image(systemName: "doc.on.doc")
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            TextEditor(text: $code)
                .font(Font.custom("Pretendard", size: 13))
                .frame(minHeight: 108)
                .foregroundStyle(.lbSecondary)
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray100, lineWidth: 1)
                }
            
        }
        .padding(.horizontal, 16)
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
        .onChange(of: detail) {
            code = detail.code
        }
        .onChange(of: code) {
            detail.code = code
        }
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(code, forType: .string)
    }
}
