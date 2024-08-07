//
//  HomeView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \Project.lastEditDate, order: .reverse) var projects: [Project]
    @State private var navigationPath: [Project] = []
    @Environment(\.modelContext) var context
    
    var body: some View {
        NavigationStack {
            HStack {
                // TODO: 폰트 수정
                Text("프로젝트")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    addProject(Project(title: "Untitled \(projects.count + 1)"))
                } label: {
                    // TODO: 폰트 수정
                    Text("새 프로젝트 생성")
                        .font(.system(size: 16))
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
        try? context.save()
    }
    
    private func deleteProject(_ project: Project) {
        context.delete(project)
        try? context.save()
    }

    private func updateProjectTitle(_ project: Project, title: String) {
        project.title = title
    }
}

struct AddProjectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(configuration.isPressed ? .purple500 : .purple400)
            .cornerRadius(8.0)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Project.self)
}
