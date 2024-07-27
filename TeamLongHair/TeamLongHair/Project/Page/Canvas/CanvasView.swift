//
//  CavasView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftUI

struct CanvasView: View {
    // 원 크기
    @State var line: CGFloat = 50
    @State var links: [TempLink] = [
        .init(1),
        .init(childs: [.init(6), .init(7)], 2),
        .init(childs: [.init(childs: [.init(9)], 8), .init(childs: [.init(11), .init(12)], 10)], 3),
        .init(4),
        .init(5)
    ]
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            HStack(alignment: .top, spacing: 0) {
                // 수평으로 한 번 그려주기
                ForEach(links) { item in
                    VStack(alignment: .leading,spacing: 0) {
                        HStack(spacing: 0) {
                            Circle()
                                .frame(width: line)
                                .foregroundStyle(.purple)
                                .overlay {
                                    Text("\(item.details)")
                                }
                            Rectangle()
                                .frame(minWidth: line * 0.5, maxWidth: .infinity, maxHeight: 1)
                        }
                        // 수직으로 반복해서 그려주기
                        DrawNodes(line: line, links: item.childs)
                    }
                }
            }
        }
    }
}

struct DrawNodes: View {
    @State var line: CGFloat
    @State var links: [TempLink]
    
    var body: some View {
        ForEach(links) { item in
            HStack(alignment: .top, spacing: 0) {
                ZStack {
                    Spacer()
                        .frame(width: line, height: line)
                    HStack {
                        Spacer()
                            .frame(width: line / 2)
                        Rectangle()
                            .frame(width: line / 2, height: 1)
                    }
                }
                VStack(alignment: .leading, spacing: 0) {
                    Circle()
                        .frame(width: line, height: line)
                        .foregroundStyle(.purple)
                        .overlay {
                            Text("\(item.details)")
                        }
                    if !item.childs.isEmpty {
                        DrawNodes(line: line, links: item.childs)
                    }
                }
            }
            .overlay(alignment: .leading) {
                if item.id != links.last?.id {
                    Spacer()
                        .frame(width: line)
                    Rectangle()
                        .frame(width: 1)
                } else {
                    Spacer()
                        .frame(width: line)
                    VStack {
                        Rectangle()
                            .frame(width: 1, height: line / 2)
                        Spacer()
                    }
                }
            }
        }
    }
}

// 임시 구조체
struct TempLink: Identifiable {
    let id: UUID = UUID()
    var childs: [TempLink]
    var details: Int
    
    init(childs: [TempLink] = .init(), _ details: Int) {
        self.childs = childs
        self.details = details
    }
}

#Preview {
    CanvasView()
}
