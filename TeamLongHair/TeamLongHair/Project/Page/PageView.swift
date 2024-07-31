//
//  PageView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftUI

struct PageView: View {
    var project: Project
    
    var body: some View {
        HStack {
            ForEach(project.pages) { page in
                    Text(page.title)
            }
            
            
            CanvasView()
        }
        .onAppear {
            updateProjectLastEditDate(project)
        }
    }
    
    private func updateProjectLastEditDate(_ project: Project) {
        project.lastEditDate = Date.now
    }
}

//#Preview {
//    PageView()
//}
