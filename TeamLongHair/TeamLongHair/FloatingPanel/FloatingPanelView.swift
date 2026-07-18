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
    @State private var projectIndex: Int = 0
    @State private var pageIndex: Int = 0

    var minWidth: CGFloat = 500.0
    var minHeight: CGFloat = 512.0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VisualEffectView()
                //TODO: f9f9f9 컬러에셋으로 변경
                Color.white000
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

                    
                    RoundedTextField(fieldState: $fieldState, text: $panelTitleText, currentField: .title, placeholder: "제목을 입력해 주세요", cornerRadius: 8)
                        .foregroundStyle(Color.gray050)
                        .padding(.top, 8)
                        .focused($focusedField, equals: .title)
                        .onSubmit {
                            focusedField = nil
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
                            
                            PanelPageListView(fieldState: $fieldState, selectedIndex: $pageIndex, itemList: currentProjectPages)
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
        .onChange(of: focusedField) { _, newValue in
            switch focusedField {
            case .url, .title:
                fieldState = focusedField ?? .url
            default:
                break
            }
        }
        .onChange(of: appState.isArrowKeyToggle) { _, _ in
            checkArrowKeyAction()
        }
        .onChange(of: appState.shouldSaveDataToggle) { _, _ in
                if panelURLText.isEmpty {
                    focusedField = .url
                    fieldState = .url
                } else if panelTitleText.isEmpty {
                    focusedField = .title
                    fieldState = .title
                } else if let targetPage = resolvedTargetPage() {
                    let newLinkDetail = LinkDetail(URL: panelURLText, title: panelTitleText)
                    let newLink = Link(detail: newLinkDetail,
                                       sortIndex: (targetPage.sortedLinks.last?.sortIndex ?? -1) + 1)
                    targetPage.links.append(newLink)
                    LinkMetadataApply.fetchAndApply(to: newLinkDetail)

                    appState.isPanelPresented = false
                    resetPanelInput()
                }
        }
        .onChange(of: appState.isPanelPresented) { _, isPresented in
            guard isPresented else {
                resetPanelInput()
                return
            }
            syncTargetToCurrentView()
            if let tab = appState.pendingTabInfo {
                if panelURLText.isEmpty { panelURLText = tab.url }
                if panelTitleText.isEmpty { panelTitleText = tab.title }
                appState.pendingTabInfo = nil
            }
        }
        .frame(minWidth: minWidth, minHeight: minHeight)
    }
    
    /// 패널이 열릴 때, 저장 대상을 현재 열려 있는 프로젝트/페이지로 기본 선택한다.
    /// 해당 ID를 찾지 못하면(홈 화면 등) 가장 최근 편집한 프로젝트(0번)로 폴백.
    private func syncTargetToCurrentView() {
        guard !projects.isEmpty else { return }
        if let pid = appState.currentProjectID,
           let index = projects.firstIndex(where: { $0.id == pid }) {
            projectIndex = index
        } else {
            projectIndex = 0
        }
        let targetPages = projects[projectIndex].pages
        if let pageID = appState.currentPageID,
           let index = targetPages.firstIndex(where: { $0.id == pageID }) {
            pageIndex = index
        } else {
            pageIndex = 0
        }
    }

    /// 현재 선택된 프로젝트의 페이지 목록(projectIndex가 범위 밖이면 빈 배열).
    /// body와 방향키 처리에서 projects[projectIndex] 직접 접근에 의한 크래시를 막는다.
    private var currentProjectPages: [Page] {
        guard projects.indices.contains(projectIndex) else { return [] }
        return projects[projectIndex].pages
    }

    /// 현재 선택된 인덱스로 저장 대상 페이지를 안전하게 해석한다(범위 밖이면 nil).
    private func resolvedTargetPage() -> Page? {
        guard projects.indices.contains(projectIndex) else { return nil }
        let targetPages = projects[projectIndex].pages
        guard targetPages.indices.contains(pageIndex) else { return nil }
        return targetPages[pageIndex]
    }

    func resetPanelInput() {
        fieldState = .url
        panelTitleText = ""
        panelURLText = ""
        projectIndex = 0
        pageIndex = 0
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
                    pageIndex = 0   // 프로젝트가 바뀌면 페이지 선택을 초기화(저장 대상 불일치 방지)
                }
            case .up:
                if projectIndex > 0 {
                    projectIndex -= 1
                    pageIndex = 0
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
                if pageIndex < currentProjectPages.count - 1 {
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

