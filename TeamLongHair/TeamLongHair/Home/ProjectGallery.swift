//
//  ProjectGallery.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/30/24.
//

import SwiftUI

struct ProjectGallery: View {
    var projects: [Project]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 20) {
                ForEach(projects) { project in
                    NavigationLink {
                        Text("page view")
                    } label: {
                        VStack(alignment: .leading, spacing: 0) {
                            RoundedRectangle(cornerRadius: 12)
                                .frame(height: 200)
                                .foregroundStyle(.clear)
                                .padding(.bottom, 8)
                            
                            Text(project.title)
                        }
                    }
                }
            }
            .padding()
        }
    }
}
