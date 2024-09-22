//
//  LinkView.swift
//  TeamLongHair
//
//  Created by 김준수(엘빈) on 8/2/24.
//

import SwiftUI

struct LinkView: View {
    @State private var showIconPicker: Bool = false
    @State var url: String = ""
    
    var detail: LinkDetail
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    showIconPicker = true
                } label: {
                    Image(detail.icon.imageName(color: detail.color))
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 32, height: 32)
                .popover(isPresented: $showIconPicker) {
                    VStack {
                        ForEach(Icon.allCases, id: \.self) { icon in
                            Button {
                                detail.icon = icon
                                showIconPicker = false
                            } label: {
                                Image(icon.imageName(color: detail.color))
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .padding(4)
                            }
                        }
                    }
                    .padding()
                }
                
                Text(detail.title)
                    .font(Font.custom("Pretendard", size: 16))
                    .lineLimit(1)
                    .fontWeight(.bold)
                    .foregroundColor(.lbPrimary)
                
                Spacer()
                
                Button {
                    // TODO: 공유 기능 추가
                    
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 32, height: 32)
                        .scaledToFit()
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            TextField(url, text: $url)
                .font(Font.custom("Pretendard", size: 12))
                .textFieldStyle(.plain)
                .foregroundStyle(.lbTertiary)
                .padding(8)
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray050, lineWidth: 1)
                        .foregroundColor(.white000)
                    }
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 16)
        .frame(width: 300)
        .onTapGesture {
            if showIconPicker {
                showIconPicker = false
            }
        }
        .onChange(of: detail) {
            url = detail.URL
        }
        .onChange(of: url) {
            detail.URL = url
        }
    }
}
