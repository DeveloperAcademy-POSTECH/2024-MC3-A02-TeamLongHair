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
    @State private var selectedProject: Project?
    @Environment(\.modelContext) var context
    @AppStorage("hasSeenPermissionOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false
    
    var body: some View {
        Group {
            if let selectedProject {
                ProjectView(project: selectedProject) {
                    self.selectedProject = nil
                }
            } else {
                galleryContent
            }
        }
        .background(.white000)
        .onAppear {
            if !hasSeenOnboarding { showOnboarding = true }
        }
        .sheet(isPresented: $showOnboarding) {
            PermissionOnboardingSheet {
                hasSeenOnboarding = true
                showOnboarding = false
            }
        }
    }

    private var galleryContent: some View {
        VStack(spacing: 0) {
            HStack {
                // TODO: 폰트 수정
                Text("프로젝트")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.secondary)

                Spacer()

                AppearanceMenu()
                    .padding(.trailing, 8)

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
                selectedProject = project
            } deleteProject: { project in
                if selectedProject?.id == project.id { selectedProject = nil }
                deleteProject(project)
            }
        }
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
