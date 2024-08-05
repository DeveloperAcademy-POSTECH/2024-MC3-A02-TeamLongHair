//
//  FloatingPanelView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftUI

struct FloatingPanelView: View {
    @State private var showingPanel = false
    @State private var panelTitleText = ""
    @State private var panelURLText = ""
    var body: some View {
        Button("Present panel") {
            showingPanel.toggle()
        }
        .floatingPanel(isPresented: $showingPanel) {
            FloatingPanelExpandableLayout(toolbar: {
                VStack {
                    TextField(text: $panelURLText) {
                        Text("URL")
                    }
                    TextField(text: $panelTitleText) {
                        Text("Title")
                    }
                }
            }, projectBar: {
                Text("ProjectList")
            }, pageBar: {
                Text("PageList")
            })
        }
    }
}

#Preview {
    FloatingPanelView()
}
