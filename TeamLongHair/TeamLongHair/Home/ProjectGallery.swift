//
//  ProjectGallery.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/30/24.
//

import SwiftUI

struct ProjectGallery: View {
    var projects: [Project]
    let openProject: (Project) -> Void
    let deleteProject: (Project) -> Void
    let createProject: () -> Void

    @State private var isEditing = false
    @State private var editingTitle = ""
    @State private var editingProject: Project? = nil
    @State private var hoveredProjectID: UUID? = nil

    var body: some View {
        if projects.isEmpty {
            emptyState
        } else {
            grid
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 20)], spacing: 24) {
                ForEach(projects) { project in
                    card(project)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    @ViewBuilder
    private func card(_ project: Project) -> some View {
        let isHovered = hoveredProjectID == project.id
        VStack(alignment: .leading, spacing: 8) {
            Button {
                openProject(project)
            } label: {
                ProjectCoverView(project: project)
            }
            .buttonStyle(defaultButtonStyle())

            if isEditing && project.id == editingProject?.id {
                TextField("이름 입력", text: $editingTitle) {
                    project.updateTitle(newTitle: editingTitle)
                    isEditing = false
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                Text(project.title)
                    .foregroundStyle(.primary)
                    .font(.system(size: 16))
                    .lineLimit(1)
            }

            Text(metaText(project))
                .foregroundStyle(.tertiary)
                .font(.system(size: 13))
                .lineLimit(1)
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(isHovered ? Color.gray.opacity(0.08) : Color.clear)
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .onHover { hovering in
            if hovering { hoveredProjectID = project.id }
            else if hoveredProjectID == project.id { hoveredProjectID = nil }
        }
        .contextMenu {
            Button("이름 변경") {
                editingTitle = project.title
                editingProject = project
                isEditing = true
            }
            Button("삭제", role: .destructive) {
                deleteProject(project)
            }
            .keyboardShortcut(.delete)
        }
    }

    private func metaText(_ project: Project) -> String {
        let rel = ProjectCardFormatting.relativeEditLabel(from: project.lastEditDate, now: Date())
        return "\(project.pages.count)페이지 · \(project.totalLinkCount)링크 · \(rel)"
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.on.square.dashed")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("아직 프로젝트가 없어요")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
            Text("새 프로젝트를 만들어 탭을 모아보세요")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Button {
                createProject()
            } label: {
                Text("새 프로젝트 생성")
                    .font(.system(size: 14))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .buttonStyle(AddProjectButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// TODO: 이후에 rebase 받고 Util 폴더로 뺄 예정
struct defaultButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
