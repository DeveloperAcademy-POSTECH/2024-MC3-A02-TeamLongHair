//
//  ProjectView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftUI

struct ProjectView: View {
    var project: Project
    let onBack: () -> Void

    @State var page: Page
    @State var link: Link?
    /// 리스트에서 링크 클릭 시 캔버스가 해당 노드로 뷰포트를 이동하도록 전달하는 요청.
    @State private var focusRequest: UUID?
    @State private var appState = AppState.shared
    @State private var toastText: String?

    @State private var isShowingRightPanel = false
    @State private var isShowingTextField = false

    @State private var editingTitle: String = ""

    init(project: Project, onBack: @escaping () -> Void) {
        self.project = project
        self.onBack = onBack
        self.page = self.project.pages[0]
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    onBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("프로젝트")
                    }
                    .font(.system(size: 14))
                    .foregroundStyle(.lbPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(defaultButtonStyle())
                .padding(.horizontal, 8)
                .padding(.top, 12)

                HStack(spacing: 8) {
                    Text("\(project.title)")
                        .font(.system(size: 16))
                        .foregroundStyle(.lbPrimary)
                        .lineLimit(1)
                    
                    Button {
                        isShowingTextField.toggle()
                    } label: {
                        Image(systemName: "chevron.down")
                    }
                    .buttonStyle(defaultButtonStyle())
                }
                .padding(20)
                                
                if isShowingTextField {
                    TextField("Enter new title", text: $editingTitle) {
                        project.updateTitle(newTitle: editingTitle)
                        isShowingTextField = false
                    }
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .foregroundStyle(.lbPrimary)
                    .padding(8)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.purple400, lineWidth: 1)
                            .foregroundColor(.white000)
                    }
                    .padding([.horizontal, .bottom], 12)
                }

                LinkPanelView(project: project, pages: project.pages, selectedPage: $page, selectedLink: $link, focusRequest: $focusRequest)
            }
            .background(.white000)
            .frame(minWidth: 300)
        } detail: {
            CanvasView(selectedPage: $page, selectedLink: $link, focusRequest: $focusRequest)
                .inspector(isPresented: $isShowingRightPanel) {
                    DetailPanelView(selectedLink: $link)
                        .inspectorColumnWidth(min: 320, ideal: 380, max: 640)
                }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    isShowingRightPanel.toggle()
                } label: {
                    Image(systemName: "sidebar.right")
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let toastText {
                ToastView(text: toastText)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: appState.lastIngest) { _, receipt in
            guard let receipt else { return }
            withAnimation { toastText = "\(receipt.count)개 링크를 '\(receipt.targetName)'에 추가" }
            let shownID = receipt.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                // 그 사이 새 수집이 없었을 때만 숨긴다.
                if appState.lastIngest?.id == shownID {
                    withAnimation { toastText = nil }
                }
            }
        }
        .onAppear {
            updateProjectLastEditDate(project)
            AppState.shared.currentProjectID = project.id
            AppState.shared.currentPageID = page.id
        }
        .onChange(of: page) {
            AppState.shared.currentPageID = page.id
        }
        .onChange(of: link) {
            isShowingRightPanel = true
        }
    }
    
    private func updateProjectLastEditDate(_ project: Project) {
        project.lastEditDate = Date.now
    }
}

//#Preview {
//    ProjectView()
//}
