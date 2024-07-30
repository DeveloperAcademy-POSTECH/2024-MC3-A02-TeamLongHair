//
//  HomeView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftData
import SwiftUI

struct HomeView: View {
    @Query var projects: [Project]
    @State private var navigationPath: [Project] = []
    @Environment(\.modelContext) var context
    
    // To Do - Yu:D
    // 최근 편집 순으로 정렬하기. 최근 편집? 최근 접속?
    // 최근 편집은 어떻게 판단?
    
    var body: some View {
        NavigationStack {
            HStack {
                Text("프로젝트")
                    .font(.system(size: 32))
                
                Spacer()
                
                Button {
                    addProject(Project(title: "Untitled"))
                } label: {
                    Text("새 프로젝트 생성")
                        .padding(16)
                }
            }
            .padding(24)
            
            ProjectGallery(projects: projects)
        }
    }
    
    private func addProject(_ project: Project) {
        context.insert(project)
    }
    
    private func deleteProject(_ project: Project) {
        context.delete(project)
    }

    private func updateProjectTitle(_ project: Project, title: String) {
        project.title = title
    }
}

#Preview {
    HomeView()
}
