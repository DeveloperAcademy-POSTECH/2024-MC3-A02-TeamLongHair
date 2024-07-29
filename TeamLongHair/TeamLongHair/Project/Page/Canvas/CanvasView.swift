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
        .init(2, 
              childs: [
            .init(6),
            .init(7)
        ]),
        .init(3,
              childs: [
            .init(8, 
                  childs: [
                .init(9)
            ]),
            .init(10,
                  childs: [
                .init(11),
                .init(12),
                .init(123)
            ])
        ]),
        .init(4),
        .init(5),
        .init(100)
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
                            if let last = links.last {
                                if last.id != item.id {
                                    Rectangle()
                                        .frame(minWidth: line * 0.5, maxWidth: .infinity, maxHeight: 1)
                                }
                            }
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
    
    init(_ details: Int, childs: [TempLink] = .init()) {
        self.childs = childs
        self.details = details
    }
}

#Preview {
    CanvasView()
}
