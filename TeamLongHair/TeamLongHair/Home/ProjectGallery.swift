//
//  ProjectGallery.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/30/24.
//

import SwiftUI

struct ProjectGallery: View {
    var projects: [Project]
    let deleteProject: (Project) -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320))]) {
                ForEach(projects) { project in
                    NavigationLink {
                        // TODO: 페이지 + 캔버스 뷰
                        Text("page view")
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            // TODO: 색상? 이미지? 변경
                            RoundedRectangle(cornerRadius: 8)
                                .frame(height: 220)
                            
                            Text(project.title)
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 12, bottom: 48, trailing: 12))
                    .contextMenu {
                        Button("Delete") {
                            deleteProject(project)
                        }
                        .keyboardShortcut(.delete)
                        
                        Button("Edit") {
                            // TODO: 프로젝트 타이틀 Edit 작업 추가
                            print("Edit")
                        }
                    }
                }
            }
            .padding()
        }
    }
}
