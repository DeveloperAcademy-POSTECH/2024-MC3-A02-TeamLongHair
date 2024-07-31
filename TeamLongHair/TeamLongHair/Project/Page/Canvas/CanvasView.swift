//
//  CanvasView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftUI

struct CanvasView: View {
    // 원 크기
    @State var sizeOfCircle: CGFloat = 50
    // 줌값 유지를 위한 변수
    @State var lastScaleValue: CGFloat = 1.0
    
    @State var links: [TempLink] = [
        .init(1),
        .init(2,
              childs: [
                .init(3),
                .init(4)
              ]),
        .init(5,
              childs: [
                .init(6,
                      childs: [
                        .init(7)
                      ]),
                .init(8,
                      childs: [
                        .init(9, childs: [
                            .init(10)
                        ]),
                        .init(11),
                        .init(12)
                      ])
              ]),
        .init(13),
        .init(14),
        .init(15)
    ]
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            HStack(alignment: .top, spacing: 0) {
                // 수평으로 한 번 그려주기
                ForEach(links) { link in
                    HStack(alignment: .top, spacing: 0) {
                        ZStack(alignment: .topLeading) {
                            // 맨 위 가로선 그리는 방법 변경
                            // 왜냐하면 하위 링크가 늘어났을 때 선이 끝까지 안 그려지는 버그가 있었어서
                            if let last = links.last {
                                if last.id != link.id {
                                    VStack(spacing: 0) {
                                        Spacer()
                                            .frame(height: sizeOfCircle * 0.5)
                                        Rectangle()
                                            .frame(minWidth: sizeOfCircle * 2, maxWidth: .infinity, maxHeight: 1)
                                    }
                                }
                            }
                            VStack(alignment: .leading, spacing: 0) {
                                Circle()
                                    .frame(width: sizeOfCircle, height: sizeOfCircle)
                                    .foregroundStyle(.purple)
                                    .overlay {
                                        Text("\(link.details)")
                                            .font(.system(size: sizeOfCircle * 0.3))
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
            // 창을 늘려도 그래프가 유지됐으면 좋겠어서 고정
            .fixedSize()
            .padding(50)
        }
        // 이거 하면 뷰가 그려지지 않은 빈 공간에서도 제스처를 인식한대요
        .contentShape(Rectangle())
        // 줌 제스처
        .gesture(
            MagnifyGesture()
                .onChanged { value in
                    let delta = value.magnification / self.lastScaleValue
                    self.lastScaleValue = value.magnification
                    let newScale = self.sizeOfCircle * delta
                    
                    if newScale < 100 && newScale > 25 {
                        self.sizeOfCircle = newScale
                    }
                    
                }
                .onEnded { val in
                    self.lastScaleValue = 1.0
                }
        )
        // 줌 비율
        .overlay(alignment: .bottomTrailing) {
            HStack {
                Text(Image(systemName: "plus.magnifyingglass"))
                Text("\(sizeOfCircle * (1 / 50) * 100)%")
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
                                .font(.system(size: sizeOfCircle * 0.3))
                        }
                        .draggable("\(link.id)")
                    
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
