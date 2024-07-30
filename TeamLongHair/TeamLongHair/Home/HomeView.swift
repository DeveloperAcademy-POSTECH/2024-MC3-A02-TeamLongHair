//
//  HomeView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftData
import SwiftUI

struct HomeView: View {
    // TODO: 최근 편집 순으로 정렬하기.
    // 최근 편집? 최근 접속? 최근 편집은 어떻게 판단?
    @Query var projects: [Project]
    @State private var navigationPath: [Project] = []
    @Environment(\.modelContext) var context
    
    var body: some View {
        NavigationStack {
            HStack {
                // TODO: 폰트 수정
                Text("프로젝트")
                    .font(.system(size: 32, weight: .bold))
                
                Spacer()
                
                Button {
                    addProject(Project(title: "Untitled"))
                } label: {
                    // TODO: 폰트 수정
                    Text("새 프로젝트 생성")
                        .padding(16)
                }
                .buttonStyle(AddProjectButtonStyle())
            }
            .padding(48)
            
            ProjectGallery(projects: projects) { project in
                deleteProject(project)
            }
        }
        .background(.white)
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

// TODO: 색상 수정
struct AddProjectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(configuration.isPressed ? .purple : .black)
            .cornerRadius(8.0)
    }
}


#Preview {
    HomeView()
}
