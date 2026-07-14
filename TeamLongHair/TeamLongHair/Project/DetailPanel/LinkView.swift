//
//  LinkView.swift
//  TeamLongHair
//
//  Created by 김준수(엘빈) on 8/2/24.
//

import SwiftUI

struct LinkView: View {
    @State private var showIconPicker: Bool = false
    var link: Link
    var detail: LinkDetail

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    showIconPicker = true
                }, label: {
                    Image(detail.icon.imageName(color: detail.color))
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
                                detail.icon = icon
                                showIconPicker = false
                            }, label: {
                                Image(icon.imageName(color: detail.color))
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .padding(4)
                            })
                        }
                    }
                    .padding()
                }
                
                TextField("제목", text: Binding(get: { detail.title }, set: { detail.title = $0 }))
                    .textFieldStyle(.plain)
                    .font(
                        Font.custom("Pretendard", size: 16)
                            .weight(.bold)
                    )
                    .foregroundColor(.lbPrimary)
                Spacer()
                Button(action: {
                    link.openInBrowser()
                }, label: {
                    Image(systemName: "safari")
                })
                .buttonStyle(PlainButtonStyle())
                .frame(width: 32, height: 32)
                .padding(12)
                .help("브라우저에서 열기")
            }

            TextField("URL", text: Binding(get: { detail.URL }, set: { detail.URL = $0 }))
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
        .frame(width: 300, height: 118)
        .onTapGesture {
            if showIconPicker {
                showIconPicker = false
            }
        }
    }
}
