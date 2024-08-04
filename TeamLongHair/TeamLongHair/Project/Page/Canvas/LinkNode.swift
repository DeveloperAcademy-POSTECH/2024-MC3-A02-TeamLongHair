//
//  LinkNode.swift
//  TeamLongHair
//
//  Created by Lee Sihyeong on 8/4/24.
//

import SwiftUI

struct LinkNode: View {
    @Binding var sizeOfNode: CGFloat
    @Binding var link: Link
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8 * (sizeOfNode / 244))
            .stroke()
            .frame(width: sizeOfNode, height: 118 * (sizeOfNode / 244))
            .overlay {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(Image(systemName: "pencil"))
                            .frame(width: 24 * (sizeOfNode / 244), height: 24 * (sizeOfNode / 244))
                        Text("\(link.detail.title)")
                            .font(.system(size: 16 * (sizeOfNode / 244), weight: .medium))
                            .padding(.top, 4 * (sizeOfNode / 244))
                            .padding(.bottom, 12 * (sizeOfNode / 244))
                        HStack(spacing: 4 * (sizeOfNode / 244)) {
                            tagView(tag: "공식문서")
                            tagView(tag: "공식문서")
                        }
                    }
                    .padding(.leading, 16 * (sizeOfNode / 244))
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .background(.bgPrimary)
            .shadow(color: Color(red: 0.07, green: 0.09, blue: 0.1).opacity(0.05), radius: 6, x: 0, y: 4)
    }
    
    @ViewBuilder
    func tagView(tag: String) -> some View {
        RoundedRectangle(cornerRadius: 4 * (sizeOfNode / 244))
            .stroke()
            .frame(width: 68 * (sizeOfNode / 244), height: 24 * (sizeOfNode / 244))
            .background(.bgPrimary)
            .overlay {
                Text(tag)
                    .font(.system(size: 12 * (sizeOfNode / 244), weight: .regular))
            }
    }
}

#Preview {
    LinkNode(sizeOfNode: .constant(244), link: .constant(.init(detail: .init(URL: "", title: "2"))))
}
