//
//  ProjectView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftUI

struct ProjectView: View {
    var project: Project
    
    @State var page: Page
    
    init(project: Project) {
        self.project = project
        self.page = self.project.pages[0]
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            CanvasView(selectedPage: $page)
            
            PageView(project: project)
        }
    }
}

//#Preview {
//    ProjectView()
//}
