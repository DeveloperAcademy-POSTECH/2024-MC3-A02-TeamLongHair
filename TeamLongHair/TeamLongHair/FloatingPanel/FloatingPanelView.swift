//
//  FloatingPanelView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftUI
import SwiftData

enum PanelField: Hashable {
    case url
    case title
    case project
    case page
}

struct FloatingPanelView: View {
    @Environment(AppState.self) var appState: AppState
    @Query(sort: \Project.lastEditDate, order: .reverse) var projects: [Project]
    @FocusState private var focusedField: PanelField?
    @State private var fieldState: PanelField = .url
    @State private var panelTitleText = ""
    @State private var panelURLText = ""

    var minWidth: CGFloat = 500.0
    var minHeight: CGFloat = 512.0
    @State private var projectIndex: Int = 0
    @State private var pageIndex: Int = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VisualEffectView()
                //TODO: f9f9f9 컬러에셋으로 변경
                Color.white
                    .opacity(0.6)
                
                VStack(spacing: 0) {
                    RoundedTextField(fieldState: $fieldState, text: $panelURLText, currentField: .url, placeholder: "URL을 입력해 주세요", cornerRadius: 8)
                        .foregroundStyle(Color.gray050)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .url)
                        .onSubmit {
                            focusedField = .title
                            fieldState = .title
                        }
                        .onTapGesture {
                            fieldState = .url
                        }
                    
                    RoundedTextField(fieldState: $fieldState, text: $panelTitleText, currentField: .title, placeholder: "제목을 입력해 주세요", cornerRadius: 8)
                        .foregroundStyle(Color.gray050)
                        .padding(.top, 8)
                        .focused($focusedField, equals: .title)
                        .onSubmit {
                            focusedField = nil
                        }
                        .onTapGesture {
                            fieldState = .title
                        }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if projects.isEmpty {
                            Text("프로젝트 없음")
                        }else {
                            PanelProjectListView(fieldState: $fieldState, selectedIndex: $projectIndex, itemList: projects)
                                .simultaneousGesture(
                                    TapGesture()
                                    .onEnded {
                                        focusedField = nil
                                        fieldState = .project
                                    }
                                )
                            
                            PanelPageListView(fieldState: $fieldState, selectedIndex: $pageIndex, itemList: projects[projectIndex].pages)
                                .simultaneousGesture(
                                    TapGesture()
                                    .onEnded {
                                        focusedField = nil
                                        fieldState = .page
                                    }
                                )
                        }
                    }
                    
                    PanelHelpView()
                        .padding(.top, 20)
                        .padding(.bottom, 31)
                }
                .padding(.horizontal, 48)
                .padding(.top, 16)
            }
        }
        .onAppear {
            focusedField = .url
        }
        .onChange(of: appState.isArrowKeyToggled) { _, _ in
            checkArrowKeyAction()
        }
        .frame(minWidth: minWidth, minHeight: minHeight)
    }
    
    func checkArrowKeyAction() {
        switch fieldState {
        case .url:
            if appState.arrowKey == .down {
                fieldState = .title
                focusedField = .title
            }
        case .title:
            if appState.arrowKey == .down {
                fieldState = .project
                focusedField = nil
            }
            if appState.arrowKey == .up {
                fieldState = .url
                focusedField = .url
            }
        case .project:
            switch appState.arrowKey {
            case .down:
                if projectIndex < projects.count - 1 {
                    projectIndex += 1
                }
            case .up:
                if projectIndex > 0 {
                    projectIndex -= 1
                }
                if projectIndex == 0 {
                    fieldState = .title
                    focusedField = .title
                }
            case .right:
                fieldState = .page
            default:
                break
            }
        case .page:
            switch appState.arrowKey {
            case .down:
                if pageIndex < projects[projectIndex].pages.count - 1 {
                    pageIndex += 1
                }
            case .up:
                if pageIndex > 0 {
                    pageIndex -= 1
                }
            case .left:
                fieldState = .project
            default:
                break
            }
            
        }
    }
}


struct RoundedTextField: View {
    @Binding var fieldState: PanelField
    @Binding var text: String
    var currentField: PanelField = .url
    var placeholder: String = ""
    var cornerRadius: CGFloat = 10.0
    var textColor: Color = Color.gray050
    
    var body: some View {
        TextField("",
                  text: $text,
                  prompt: Text(placeholder)
                            .foregroundColor(Color.lbQuaternary)
        )
        .textFieldStyle(.plain)
        .font(.system(size: 16))
        .padding(.horizontal)
        .padding(.vertical, 13)
        .background(Color.bgPrimary)
        .foregroundColor(Color.lbPrimary)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay {
            let isCurrentFieldActivated = fieldState == currentField
            let color = isCurrentFieldActivated ? Color.purple400 : Color.lbQuaternary
            let lineWidth: CGFloat = isCurrentFieldActivated ? 2 : 1
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(color, lineWidth: lineWidth)
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

