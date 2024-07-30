//
//  ProjectModel.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/30/24.
//

import Foundation
import SwiftData

@Model
final class Project {
    @Attribute(.unique) var id: UUID
    var title: String
    @Relationship(deleteRule: .cascade) var pages: [Page] // project가 삭제되면, 그 안에 가지고 있던 page 객체도 전부 삭제
    var creationDate: Date
    var lastEditDate: Date?
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.pages = [Page(title: "Untitled")]
        self.creationDate = Date.now
        self.lastEditDate = nil
    }
}
