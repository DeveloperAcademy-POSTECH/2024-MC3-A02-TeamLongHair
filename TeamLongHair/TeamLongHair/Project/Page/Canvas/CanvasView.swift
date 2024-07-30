//
//  CavasView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftUI

struct CanvasView: View {
    // 원 크기
    var sizeOfCircle: CGFloat = 50
    
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
                ForEach(links) { link in
                    VStack(alignment: .leading,spacing: 0) {
                        HStack(spacing: 0) {
                            Circle()
                                .frame(width: sizeOfCircle)
                                .foregroundStyle(.purple)
                                .overlay {
                                    Text("\(link.details)")
                                }
                            if let last = links.last {
                                if last.id != link.id {
                                    Rectangle()
                                        .frame(minWidth: sizeOfCircle * 0.5, maxWidth: .infinity, maxHeight: 1)
                                }
                            }
                        }
                        // 수직으로 반복해서 그려주기
                        if !link.childs.isEmpty {
                            DrawNodes(sizeOfCircle: sizeOfCircle, links: link.childs)
                        }
                    }
                }
            }
        }
    }
}

struct DrawNodes: View {
    var sizeOfCircle: CGFloat
    
    @State var links: [TempLink]
    
    var body: some View {
        ForEach(links) { link in
            HStack(alignment: .top, spacing: 0) {
                ZStack {
                    Spacer()
                        .frame(width: sizeOfCircle, height: sizeOfCircle)
                    HStack {
                        Spacer()
                            .frame(width: sizeOfCircle / 2)
                        Rectangle()
                            .frame(width: sizeOfCircle / 2, height: 1)
                    }
                }
                VStack(alignment: .leading, spacing: 0) {
                    Circle()
                        .frame(width: sizeOfCircle, height: sizeOfCircle)
                        .foregroundStyle(.purple)
                        .overlay {
                            Text("\(link.details)")
                        }
                    if !link.childs.isEmpty {
                        DrawNodes(sizeOfCircle: sizeOfCircle, links: link.childs)
                    }
                }
            }
            .overlay(alignment: .leading) {
                if link.id != links.last?.id {
                    Spacer()
                        .frame(width: sizeOfCircle)
                    Rectangle()
                        .frame(width: 1)
                } else {
                    Spacer()
                        .frame(width: sizeOfCircle)
                    VStack {
                        Rectangle()
                            .frame(width: 1, height: sizeOfCircle / 2)
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
    
    init(_ details: Int, childs: [TempLink] = []) {
        self.childs = childs
        self.details = details
    }
}

#Preview {
    CanvasView()
}
