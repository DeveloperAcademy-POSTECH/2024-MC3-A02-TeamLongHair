//
//  LinkView.swift
//  TeamLongHair
//
//  Created by 김준수(엘빈) on 8/2/24.
//

import SwiftUI

struct LinkView: View {
    var link: Link
    var detail: LinkDetail

    var body: some View {
        VStack {
            HStack {
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
    }
}
