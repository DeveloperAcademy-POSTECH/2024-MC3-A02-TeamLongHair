//
//  LinkView.swift
//  TeamLongHair
//
//  Created by 김준수(엘빈) on 8/2/24.
//

import SwiftUI

struct LinkView: View {
    @State private var showIconPicker: Bool = false
    @Binding var selectedLink: Link?
    @State var url: String = ""
    
    var body: some View {
        VStack {
            if let selectedLink {
                HStack {
                    Button(action: {
                        showIconPicker = true
                    }, label: {
                        Image(selectedLink.detail.icon.imageName(color: selectedLink.detail.color))
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding(6)
                    })
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 32, height: 32)
                    .popover(isPresented: $showIconPicker) {
                        VStack {
                            ForEach(Icon.allCases, id: \.self) { icon in
                                Button(action: {
                                    selectedLink.detail.icon = icon
                                    showIconPicker = false
                                }, label: {
                                    Image(icon.imageName(color: selectedLink.detail.color))
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                        .padding(4)
                                })
                            }
                        }
                        .padding()
                    }
                    
                    Text(selectedLink.detail.title)
                        .font(
                            Font.custom("Pretendard", size: 16)
                                .weight(.bold)
                        )
                        .foregroundColor(.lbPrimary)
                    Spacer()
                    Button(action: {
                        // TODO: 공유 기능 추가
                        
                    }, label: {
                        Image(systemName: "square.and.arrow.up")
                    })
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 32, height: 32)
                    .padding(12)
                }
                
                TextField(url, text: $url)
                    .font(Font.custom("Pretendard", size: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(
                                .gray100,
                                lineWidth: 1
                            )
                    }
                    .foregroundColor(.gray900)
                    .textFieldStyle(.roundedBorder)
                    .padding(8)
            }
        }
        .frame(width: 300, height: 118)
        .onTapGesture {
            if showIconPicker {
                showIconPicker = false
            }
        }
        .onChange(of: selectedLink) {
            url = selectedLink?.detail.URL ?? ""
        }
        .onChange(of: url) {
            selectedLink?.detail.URL = url
        }
        //        .onChange(of: selectedColorIndex) { newIndex, _ in
        //            // Update the selected icon's color when the selected color changes
        //            let colorName = newIndex?.rawValue ?? "gray"
        //            selectedIcon = Icon(rawValue: "\(selectedIcon.imageName(color: IconColor(rawValue: colorName) ?? .gray))") ?? .codesnippet
        //        }
    }
}
