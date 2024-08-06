//
//  FloatingPanelView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftUI

struct FloatingPanelView: View {
    @State private var panelTitleText = ""
    @State private var panelURLText = ""
    
    var sidebarWidth: CGFloat = 256.0
    var totalWidth: CGFloat = 700.0
    var minHeight: CGFloat = 512.0
        
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VisualEffectView()
                
                Color.gray050
                    .opacity(0.6)
                
                VStack(spacing: 0) {
                    RoundedTextField(text: .constant(""), placeholder: "URL을 입력해 주세요", cornerRadius: 8)
                        .foregroundStyle(Color.gray050)
                    RoundedTextField(text: .constant(""), placeholder: "제목을 입력해 주세요", cornerRadius: 8)
                        .foregroundStyle(Color.gray050)
                        .padding(.top, 8)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        FileListView(title: "프로젝트")
                        FileListView(title: "페이지")
                    }
                    
                    PanelHelpView()
                        .padding(.top, 20)
                        .padding(.bottom, 31)
                }
                .padding(.horizontal, 48)
                .padding(.top, 16)
            }
        }
        .frame(minWidth: sidebarWidth, minHeight: minHeight)
    }
}


struct RoundedTextField: View {
    @Binding var text: String
    var placeholder: String = ""
    var cornerRadius: CGFloat = 10.0
    var textColor: Color = Color.gray050
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .font(.system(size: 16))
            .padding(.horizontal)
            .padding(.vertical, 13)
            .background(Color.bgPrimary)
            .foregroundColor(Color.lbQuaternary)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.lbQuaternary, lineWidth: 1)
            }
    }
}

struct ListItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    var isSelected: Bool = false
}

struct FileListView: View {
    var title = ""
    // 더미 배열
    @State private var dummyList: [ListItem] = [
        ListItem(title: "MC1"),
        ListItem(title: "MC2"),
        ListItem(title: "MC3")
    ]
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
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
                
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach($dummyList) { $item in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(item.isSelected ? Color.purple400 : Color.bgPrimary)
                                .overlay(alignment: .leading) {
                                    Text(item.title)
                                        .padding(.horizontal, 8)
                                        .foregroundStyle(item.isSelected ? Color.white : Color.lbSecondary)
                                }
                                .padding(.horizontal, 8)
                                .frame(height: 52)
                                .onTapGesture {
                                    // 각 아이템의 선택 상태를 토글
                                    item.isSelected.toggle()
                                }
                        }
                    }
                }
            }
        }
    }
}

struct PanelHelpView: View {
    var body: some View {
        HStack {
            Image(systemName: "arrow.up.arrow.down")
            Text("선택")
            Image(systemName: "arrow.right.to.line")
            Text("이동")
            
            Spacer()
            
            Text("esc")
            Text("닫기")
            Image(systemName: "arrow.uturn.right")
                .rotationEffect(.degrees(180))
            Text("저장")
        }
        .font(.system(size: 12))
        .foregroundStyle(Color.lbTertiary)
    }
}

#Preview {
    FloatingPanelView()
        .environment(AppState.shared)
}
