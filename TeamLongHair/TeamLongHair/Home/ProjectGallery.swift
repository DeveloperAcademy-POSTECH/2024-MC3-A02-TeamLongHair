//
//  ProjectGallery.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/30/24.
//

import SwiftUI

struct ProjectGallery: View {
    var projects: [Project]
    let deleteProject: (Project) -> Void
    let updateEditDate: (Project) -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320))]) {
                ForEach(projects) { project in
                    NavigationLink {
                        // TODO: 페이지 + 캔버스 뷰
                        Text("page view")
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            // TODO: 색상? 이미지? 변경
                            RoundedRectangle(cornerRadius: 8)
                                .frame(height: 220)
                            
                            Text(project.title)
                            
                            Text(daysSinceLastEdit(project.lastEditDate))
                        }
                        .onTapGesture {
                            updateEditDate(project)
                        }
                    }
                    .buttonStyle(projectButtonStyle())
                    .padding(EdgeInsets(top: 0, leading: 12, bottom: 48, trailing: 12))
                    .contextMenu {
                        Button("Delete") {
                            deleteProject(project)
                        }
                        .keyboardShortcut(.delete)
                        
                        Button("Edit") {
                            // TODO: 타이틀 수정 기능 추가하기
                            print("Edit")
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func daysSinceLastEdit(_ lastEditDate: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: lastEditDate, to: now)
        
        if let days = components.day {
            return "\(days)일 전 편집"
        } else {
            return "날짜 계산 오류"
        }
    }
}

struct projectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
