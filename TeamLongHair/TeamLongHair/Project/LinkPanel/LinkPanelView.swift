//
//  LinkPanelView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftUI

struct LinkPanelView: View {
    var project: Project
    var pages: [Page]
    
    @Binding var selectedPage: Page
    @Binding var selectedLink: Link?
    
    @State private var isShowingPages = true
    @State private var isShowingLinks = true
    
    @State private var editingPage: Page?
    @State private var editingTitle: String = ""

    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.bottom, 4)
            
            DisclosureGroup(isExpanded: $isShowingPages) {
                ScrollView {
                    ForEach(pages) { page in
                        if selectedPage == page {
                            pageListItembutton(page, isSelected: true)
                                .buttonStyle(selectedButtonStyle())
                        } else {
                            pageListItembutton(page, isSelected: false)
                                .buttonStyle(defaultButtonStyle())
                        }
                    }
                }
            } label: {
                HStack {
                    sectionTitleView(title: "Pages")
                    
                    Spacer()
                    
                    Button {
                        // TODO: 약간 개선 필요하다.
                        project.pages.append(Page(title: "Untitled \(project.pages.count + 1)"))
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)

                }
            }
            .padding(.horizontal, 12)
            
            Divider()
                .padding(.bottom, 4)
            
            DisclosureGroup(isExpanded: $isShowingLinks) {
                ScrollView {
                    LinkListView(links: $selectedPage.links, selectedLink: $selectedLink)
                }
            } label: {
                sectionTitleView(title: "Links")
            }
            .padding(.horizontal, 12)
            
            Spacer()
        }
        .background(.white000)
    }
    
    private func sectionTitleView(title: String) -> some View {
        Text(title)
            .font(.system(size: 14))
            .padding(.leading, 4)
            .padding(.vertical, 12)
    }
    
    private func pageListItemStyle(_ page: Page, isSelected: Bool) -> some View {
        Button {
            selectedPage = page
        } label: {
            HStack {
                Text(page.title)
                    .foregroundColor(isSelected ? .lbPrimary : .lbTertiary)
                
                Spacer()
            }
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
        }
    }
    
    private func pageListItembutton(_ page: Page, isSelected: Bool) -> some View {
        HStack {
            if editingPage == page {
                TextField("Enter new title", text: $editingTitle) {
                    editingPage?.updatePageTitle(newTitle: editingTitle)
                    editingPage = nil
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                Button {
                    selectedPage = page
                } label: {
                    HStack {
                        Text(page.title)
                            .foregroundColor(isSelected ? .lbPrimary : .lbTertiary)
                        
                        Spacer()
                    }
                    .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }
                .contextMenu {
                    Button("Rename") {
                        editingPage = page
                        editingTitle = page.title
                    }
                    
                    Button("Delete") {
                        // TODO: 타이틀 수정 기능 추가하기
                        // pages.remove(at: page)
                        print("Delete")
                    }
                    .keyboardShortcut(.delete)
                }
            }
        }
    }

}

struct selectedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
