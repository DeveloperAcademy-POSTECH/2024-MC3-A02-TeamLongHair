//
//  CanvasViewModel.swift
//  TeamLongHair
//
//  캔버스의 SwiftData 변경(재부모화)을 담당. 검증(DropValidator) 통과 후에만 변경한다.
//

import Foundation
import SwiftData

struct CanvasViewModel {
    let page: Page

    /// 링크와 그 서브트리를 삭제한다. 부모에서 분리한 뒤 context에서 삭제하면
    /// cascade 규칙으로 하위 링크와 detail까지 함께 지워진다.
    func deleteLink(id: UUID, context: ModelContext) {
        guard let link = findLink(id: id) else { return }
        detach(link)
        context.delete(link)
    }

    /// 주어진 노드와 그 모든 자손의 id 집합(삭제 시 선택 해제 판단 등에 사용).
    func subtreeIDs(of id: UUID) -> Set<UUID> {
        guard let root = findLink(id: id) else { return [] }
        var result: Set<UUID> = []
        func collect(_ link: Link) {
            result.insert(link.id)
            link.subLinks.forEach(collect)
        }
        collect(root)
        return result
    }

    /// 검증 통과 시에만 제거+삽입을 수행한다. 실패 시 트리는 변경되지 않는다.
    func moveLink(draggedIDString: String, onto targetID: UUID) -> Bool {
        guard let draggedID = UUID(uuidString: draggedIDString),
              DropValidator.canDrop(dragged: draggedID, onto: targetID, roots: page.layoutRoots),
              let dragged = findLink(id: draggedID),
              let target = findLink(id: targetID)
        else { return false }

        detach(dragged)
        dragged.sortIndex = (target.sortedSubLinks.last?.sortIndex ?? -1) + 1
        target.subLinks.append(dragged)
        return true
    }

    /// 빈 캔버스에 드롭: 루트로 승격
    func makeRoot(draggedIDString: String) -> Bool {
        guard let draggedID = UUID(uuidString: draggedIDString),
              let dragged = findLink(id: draggedID),
              !page.links.contains(where: { $0.id == draggedID })  // 이미 루트면 무시
        else { return false }

        detach(dragged)
        dragged.sortIndex = (page.sortedLinks.last?.sortIndex ?? -1) + 1
        page.links.append(dragged)
        return true
    }

    /// 레거시 데이터(sortIndex 전부 0)에 형제 순서를 부여한다.
    func normalizeSortIndices() {
        func normalize(_ links: [Link]) {
            if links.count > 1, Set(links.map(\.sortIndex)).count != links.count {
                for (index, link) in links.enumerated() {
                    link.sortIndex = index
                }
            }
            for link in links {
                normalize(link.subLinks)
            }
        }
        normalize(page.links)
    }

    private func findLink(id: UUID) -> Link? {
        func find(in links: [Link]) -> Link? {
            for link in links {
                if link.id == id { return link }
                if let found = find(in: link.subLinks) { return found }
            }
            return nil
        }
        return find(in: page.links)
    }

    /// 현재 부모(페이지 루트 배열 또는 부모 링크)에서 분리
    private func detach(_ link: Link) {
        if page.links.contains(where: { $0.id == link.id }) {
            page.links.removeAll { $0.id == link.id }
            return
        }
        func removeFromSubtree(_ parent: Link) -> Bool {
            if parent.subLinks.contains(where: { $0.id == link.id }) {
                parent.subLinks.removeAll { $0.id == link.id }
                return true
            }
            return parent.subLinks.contains { removeFromSubtree($0) }
        }
        for root in page.links where removeFromSubtree(root) { return }
    }
}
