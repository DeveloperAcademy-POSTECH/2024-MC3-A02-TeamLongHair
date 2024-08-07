//
//  LinkListView.swift
//  TeamLongHair
//
//  Created by Lee Sihyeong on 8/7/24.
//

import SwiftUI

struct LinkListView: View {
    @Binding var links: [Link]
    @Binding var selectedLink: Link?
    
    var body: some View {
        ForEach($links) { $link in
            if selectedLink == link {
                linkListItemStyle(link, isSelected: true)
                    .buttonStyle(selectedButtonStyle())
            } else {
                linkListItemStyle(link, isSelected: false)
                    .buttonStyle(defaultButtonStyle())
            }
            if !link.subLinks.isEmpty {
                LinkListView(links: $link.subLinks, selectedLink: $selectedLink)
            }
        }
    }
    
    private func linkListItemStyle(_ link: Link, isSelected: Bool) -> some View {
        Button {
            selectedLink = link
        } label: {
            HStack {
                Text(link.detail.title)
                    .foregroundColor(isSelected ? .lbPrimary : .lbTertiary)
                
                Spacer()
            }
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
        }
    }
}
