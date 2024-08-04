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
            }
            .background(.white)
            .frame(minWidth: 300)
        } detail: {
            CanvasView()
        }
        .onAppear {
            updateProjectLastEditDate(project)
        }
    }
    
    private func updateProjectLastEditDate(_ project: Project) {
        project.lastEditDate = Date.now
    }
}
