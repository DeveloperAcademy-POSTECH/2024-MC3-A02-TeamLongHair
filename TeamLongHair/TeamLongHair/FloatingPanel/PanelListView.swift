//
//  PanelListView.swift
//  TeamLongHair
//
//  Created by Damin on 8/6/24.
//

import SwiftUI

// 프로젝트 리스트 뷰
struct PanelProjectListView: View {
    @Binding var fieldState: PanelField
    @Binding var selectedIndex: Int
    @State private var isSelectedField = false
    var itemList: [Project]
    let currentField: PanelField = .project
    
    var body: some View {
        PanelListView(
            selectedIndex: $selectedIndex,
            isSelectedField: $isSelectedField,
            title: "Project",
            itemList: itemList,
            displayText: { $0.title }
        )
        .onChange(of: fieldState) { _, newValue in
            isSelectedField = currentField == newValue
        }
    }
}

// 페이지 리스트 뷰
struct PanelPageListView: View {
    @Binding var fieldState: PanelField
    @Binding var selectedIndex: Int
    @State private var isSelectedField = false
    var itemList: [Page]
    let currentField: PanelField = .page

    var body: some View {
        PanelListView(
            selectedIndex: $selectedIndex,
            isSelectedField: $isSelectedField,
            title: "Page",
            itemList: itemList,
            displayText: { $0.title }
        )
        .onChange(of: fieldState) { _, newValue in
            isSelectedField = currentField == newValue
        }
    }
}

struct PanelListView<T: Identifiable & Hashable>: View {
    @Binding var selectedIndex: Int
    @Binding var isSelectedField: Bool
    var title: String
    var itemList: [T]
    var displayText: (T) -> String

    var body: some View {
        ZStack {
            let color = isSelectedField ? Color.purple400 : Color.gray050
            let lineWidth: CGFloat = isSelectedField ? 2 : 1
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.bgPrimary)
                .stroke(color, lineWidth: lineWidth)
                .foregroundStyle(Color.bgPrimary)
                
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 14))
                    .padding(.top, 10)
                    .padding(.bottom, 9)
                    .padding(.leading)
                    .foregroundStyle(Color.lbQuaternary)
                
                Rectangle()
                    .frame(height: 2)
                    .foregroundStyle(Color.lbQuaternary)
                    .padding(.bottom, 8)
                
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(Array(itemList.enumerated()), id: \.1.id) { index, item in
                            // 아이템 선택 상태 확인
                            let isSelected = selectedIndex == index
                            let backgroundColor = isSelected ? Color.purple400 : Color.bgPrimary
                            let textColor = isSelected ? Color.white : Color.lbSecondary
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(backgroundColor)
                                .overlay(alignment: .leading) {
                                    Text(displayText(item))
                                        .padding(.horizontal, 8)
                                        .foregroundStyle(textColor)
                                }
                                .padding(.horizontal, 8)
                                .frame(height: 52)
                                .onTapGesture {
                                    selectedIndex = index
                                }
                        }
                    }
                }
            }
        }
    }
}
