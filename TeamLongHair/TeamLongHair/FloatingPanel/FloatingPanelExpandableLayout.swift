//
//  FloatingPanelExpandableLayout.swift
//  TeamLongHair
//
//  Created by Damin on 7/28/24.
//

import SwiftUI

public struct FloatingPanelExpandableLayout<Toolbar: View, ProjectBar: View, PageBar: View>: View {

    @ViewBuilder let toolbar: () -> Toolbar
    @ViewBuilder let projectBar: () -> ProjectBar
    @ViewBuilder let pageBar: () -> PageBar

    var sidebarWidth: CGFloat = 256.0
    var totalWidth: CGFloat = 512.0
    var minHeight: CGFloat = 512.0

    @State var expandedWidth = 512.0
    @Environment(\.floatingPanel) var panel

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                VisualEffectView()

                VStack(spacing: 0) {
                    HStack {
                        toolbar()
                        Spacer()

                        Button(action: toggleExpand) {
                            Image(systemName: expanded(for: geo.size.width) ?  "menubar.rectangle" : "uiwindow.split.2x1")
                        }
                        .buttonStyle(.plain)
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)

                    Divider()

                    HStack(spacing: 0) {
                        VStack {
                            Spacer()
                            projectBar()
                                .frame(minWidth: sidebarWidth, maxWidth: expanded(for: geo.size.width) ? sidebarWidth : totalWidth)
                            Spacer()
                        }

                        if expanded(for: geo.size.width) {
                            HStack(spacing: 0) {
                                Divider()
                                pageBar()
                                    .frame(width: geo.size.width - sidebarWidth)
                            }
                            .transition(.move(edge: .trailing))
                        }
                    }
                    .animation(.spring(), value: expanded(for: geo.size.width))
                }
            }
        }
        .frame(minWidth: sidebarWidth, minHeight: minHeight)
    }

    func toggleExpand() {
        if let panel = panel {
            let frame = panel.frame

            if expanded(for: frame.width) {
                expandedWidth = frame.width
            }

            let newWidth = expanded(for: frame.width) ? sidebarWidth : max(expandedWidth, totalWidth)

            let newFrame = CGRect(x: frame.midX - newWidth / 2, y: frame.origin.y, width: newWidth, height: frame.height)

            panel.setFrame(newFrame, display: true, animate: true)
        }
    }

    func expanded(for width: CGFloat) -> Bool {
        return width >= totalWidth
    }
}
