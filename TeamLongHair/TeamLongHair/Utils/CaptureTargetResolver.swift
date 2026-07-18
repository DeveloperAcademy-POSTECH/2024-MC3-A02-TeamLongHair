//
//  CaptureTargetResolver.swift
//  TeamLongHair
//
//  "지금 어느 페이지에 수집할지" 결정하는 순수 로직. 프레임워크 의존 없음(swiftc 테스트 대상).
//  SwiftData 글루는 CaptureTarget.swift가 담당한다.
//

import Foundation

/// 리졸버 입력용 프로젝트 요약(id + 페이지 id 순서).
struct ProjectRef {
    let id: UUID
    let pageIDs: [UUID]
    init(id: UUID, pageIDs: [UUID]) {
        self.id = id
        self.pageIDs = pageIDs
    }
}

/// 리졸버 결과. 인덱스는 입력 projects 배열 기준(같은 정렬 배열로 역참조).
enum CaptureResolution: Equatable {
    case existing(projectIndex: Int, pageIndex: Int)
    case createDefault
}

enum CaptureTargetResolver {
    /// projects는 최근 편집 순(내림차순)이라고 가정한다.
    /// 1) currentProjectID 매칭 → 그 프로젝트, 그 안에서 currentPageID 매칭 페이지(미매칭이면 0번).
    /// 2) currentProjectID 미매칭 → 0번(가장 최근) 프로젝트의 0번 페이지.
    /// 3) projects 비면 → createDefault.
    static func resolve(projects: [ProjectRef],
                        currentProjectID: UUID?,
                        currentPageID: UUID?) -> CaptureResolution {
        guard !projects.isEmpty else { return .createDefault }
        let projectIndex = currentProjectID
            .flatMap { id in projects.firstIndex(where: { $0.id == id }) } ?? 0
        let pageIDs = projects[projectIndex].pageIDs
        guard !pageIDs.isEmpty else { return .existing(projectIndex: projectIndex, pageIndex: 0) }
        let pageIndex = currentPageID
            .flatMap { id in pageIDs.firstIndex(of: id) } ?? 0
        return .existing(projectIndex: projectIndex, pageIndex: pageIndex)
    }
}
