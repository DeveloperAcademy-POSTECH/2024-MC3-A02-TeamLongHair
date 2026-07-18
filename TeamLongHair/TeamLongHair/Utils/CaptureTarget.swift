//
//  CaptureTarget.swift
//  TeamLongHair
//
//  CaptureTargetResolver(순수)를 SwiftData에 붙인다. 실제 Page를 돌려주고,
//  프로젝트가 하나도 없으면 기본 프로젝트를 생성한다.
//

import Foundation
import SwiftData

@MainActor
enum CaptureTarget {
    /// 수집 대상 Page. 프로젝트가 없으면 기본 "Untitled" 프로젝트를 생성해 그 첫 페이지를 반환.
    static func resolvePage(appState: AppState, context: ModelContext) -> Page? {
        let projects = fetchProjects(context)
        switch resolve(projects: projects, appState: appState) {
        case .existing(let pi, let gi):
            let pages = projects[pi].pages
            guard pages.indices.contains(gi) else { return pages.first }
            return pages[gi]
        case .createDefault:
            let project = Project(title: "Untitled")   // init이 "Untitled" 페이지 1개를 생성
            context.insert(project)
            return project.pages.first
        }
    }

    /// 팝오버에 "어디로 갈지" 미리 보여주기 위한 읽기 전용 설명(부수효과 없음).
    static func targetDescription(appState: AppState, context: ModelContext) -> String {
        let projects = fetchProjects(context)
        switch resolve(projects: projects, appState: appState) {
        case .existing(let pi, let gi):
            let project = projects[pi]
            let pageTitle = project.pages.indices.contains(gi) ? project.pages[gi].title
                          : (project.pages.first?.title ?? "")
            return "\(project.title) · \(pageTitle)"
        case .createDefault:
            return "새 프로젝트가 생성됩니다"
        }
    }

    // MARK: - Helpers

    private static func fetchProjects(_ context: ModelContext) -> [Project] {
        let descriptor = FetchDescriptor<Project>(
            sortBy: [SortDescriptor(\.lastEditDate, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    private static func resolve(projects: [Project], appState: AppState) -> CaptureResolution {
        let refs = projects.map { ProjectRef(id: $0.id, pageIDs: $0.pages.map(\.id)) }
        return CaptureTargetResolver.resolve(projects: refs,
                                             currentProjectID: appState.currentProjectID,
                                             currentPageID: appState.currentPageID)
    }
}
