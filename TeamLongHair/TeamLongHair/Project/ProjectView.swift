//
//  ProjectView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftUI

struct ProjectView: View {
    var project: Project
    
    @State var page: Page
    @State var link: Link?
    @State private var isShowingRightPanel = false
    @State private var isShowingTextField = false
    
    init(project: Project) {
        self.project = project
        self.page = self.project.pages[0]
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 0) {
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
                
                // TODO: 프로젝트 타이틀 입력받을 text field + update 로직 넣기
                
                LinkPanelView(pages: project.pages, selectedPage: $page, selectedLink: $link)
            }
            .background(.white)
            .frame(minWidth: 300)
        } detail: {
            CanvasView(selectedPage: $page)
                .inspector(isPresented: $isShowingRightPanel) {
                    // TODO: 우측 패널 view 넣기
                    VStack(alignment: .leading, spacing: 8) {
                        Text("쌸라 쌸라")
                    }
                    .inspectorColumnWidth(min: 300, ideal: 300, max: 300)
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
        .onAppear {
            updateProjectLastEditDate(project)
        }
    }
    
    private func updateProjectLastEditDate(_ project: Project) {
        project.lastEditDate = Date.now
    }
}
