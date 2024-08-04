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
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320))]) {
                ForEach(projects) { project in
                    VStack(alignment: .leading, spacing: 8) {
                        NavigationLink {
                            PageView(project: project)
                        } label: {
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundStyle(.gray050)
                                .frame(height: 220)
                        }
                        
                        Text(project.title)
                            .foregroundColor(.primary)
                            .font(.system(size: 16))
                            .lineLimit(1)
                        
                        Text(daysSinceLastEdit(project.lastEditDate))
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(defaultButtonStyle())
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

// TODO: 이후에 rebase 받고 Util 폴더로 뺄 예정
struct defaultButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
