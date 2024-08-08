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
    @State var isSelected: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8 * (sizeOfNode / 244))
            .stroke(style: StrokeStyle(lineWidth: isSelected ? 3 * (sizeOfNode / 244) : 1 * (sizeOfNode / 244)))
            .foregroundStyle(link.detail.color.returnColor())
            .frame(width: sizeOfNode, height: 118 * (sizeOfNode / 244))
            .overlay {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Image(link.detail.icon.imageName(color: link.detail.color))
                            .resizable()
                            .frame(width: 20 * (sizeOfNode / 244), height: 20 * (sizeOfNode / 244))
                        Text("\(link.detail.title)")
                            .font(.system(size: 16 * (sizeOfNode / 244), weight: .medium))
                            .padding(.top, 4 * (sizeOfNode / 244))
                            .padding(.bottom, 12 * (sizeOfNode / 244))
                        HStack(spacing: 4 * (sizeOfNode / 244)) {
                            ForEach(link.detail.tags, id: \.self) { tag in
                                tagView(tag: tag)
                            }
                        }
                        .frame(height: 24 * (sizeOfNode / 244))
                    }
                    .padding(.leading, 16 * (sizeOfNode / 244))
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .background {
                Color.bgPrimary
                    .shadow(color: link.detail.color.returnColor().opacity(isSelected ? 0.2 : 0.1), radius: 6, x: 0, y: 4)
            }
            
    }
    
    @ViewBuilder
    func tagView(tag: String) -> some View {
        RoundedRectangle(cornerRadius: 4 * (sizeOfNode / 244))
            .stroke()
            .foregroundStyle(.gray100)
            .frame(width: 68 * (sizeOfNode / 244), height: 24 * (sizeOfNode / 244))
            .background(.bgPrimary)
            .overlay {
                Text(tag)
                    .font(.system(size: 12 * (sizeOfNode / 244), weight: .regular))
            }
    }
}

#Preview {
    LinkNode(sizeOfNode: .constant(244), link: .constant(.init(detail: .init(URL: "", title: "2"))), isSelected: true)
}
