//
//  DetailPanelView.swift
//  TeamLongHair
//
//  Created by 김준수(엘빈) on 8/2/24.
//

import SwiftUI

struct DetailPanelView: View {
    @Binding var selectedLink: Link?

    var body: some View {
        if let link = selectedLink {
            ScrollView {
                VStack(spacing: 12) {
                    LinkHeaderView(link: link, detail: link.detail)
                    urlRow(link.detail)
                    Divider()
                    LinkDescriptionView(detail: link.detail)
                    MemoView(detail: link.detail)
                    Divider()
                    TagView(detail: link.detail)
                    Divider()
                    ColorView(detail: link.detail)
                    Divider()
                    savedDateRow(link.detail)
                }
                .padding(.vertical, 12)
            }
            .frame(width: 300)
            .background(Color.bgPrimary)
            .onAppear {
                LinkMetadataApply.fetchAndApply(to: link.detail)
            }
            .onChange(of: link.id) {
                LinkMetadataApply.fetchAndApply(to: link.detail)
            }
        }
    }

    private func urlRow(_ detail: LinkDetail) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("URL").font(.system(size: 14, weight: .bold)).foregroundStyle(.lbPrimary)
            TextField("https://…", text: Binding(get: { detail.URL }, set: { detail.URL = $0 }))
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
                .foregroundStyle(.lbSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
    }

    private func savedDateRow(_ detail: LinkDetail) -> some View {
        HStack {
            Text("저장").font(.system(size: 14, weight: .bold)).foregroundStyle(.lbPrimary)
            Spacer()
            Text(detail.savedDate.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 12)).foregroundStyle(.lbTertiary)
        }
        .padding(.horizontal, 12)
    }
}

//struct RightPanelView_Previews: PreviewProvider {
//    static var previews: some View {
//        DetailPanelView()
//    }
//}
