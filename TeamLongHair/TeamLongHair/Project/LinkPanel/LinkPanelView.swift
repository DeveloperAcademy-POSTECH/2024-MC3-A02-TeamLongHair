//
//  LinkPanelView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftData
import SwiftUI

struct LinkPanelView: View {
    var project: Project
    var pages: [Page]

    @Binding var selectedPage: Page
    @Binding var selectedLink: Link?

    @Environment(\.modelContext) private var context

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
                    LinkListView(links: selectedPage.sortedLinks, selectedLink: $selectedLink)
                }
            } label: {
                sectionTitleView(title: "Links")
            }
            .padding(.horizontal, 12)
            
            Spacer()
        }
        .background(.white000)
    }
    
    /// 페이지 삭제. 선택된 페이지를 지우면 먼저 다른 페이지로 선택을 옮긴 뒤 삭제한다
    /// (non-optional 바인딩이 삭제된 객체를 참조해 크래시하는 것을 막기 위함).
    /// cascade 삭제 규칙으로 페이지가 지워지면 그 하위 링크도 함께 삭제된다.
    private func deletePage(_ page: Page) {
        // 프로젝트에는 최소 한 페이지가 있어야 한다 (ProjectView가 pages[0]을 사용).
        guard project.pages.count > 1 else { return }

        if editingPage == page { editingPage = nil }

        if selectedPage == page,
           let fallback = project.pages.first(where: { $0.id != page.id }) {
            selectedPage = fallback
            selectedLink = nil
        }

        project.pages.removeAll { $0.id == page.id }
        context.delete(page)
        try? context.save()
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
                        deletePage(page)
                    }
                    .keyboardShortcut(.delete)
                    .disabled(project.pages.count <= 1)
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
