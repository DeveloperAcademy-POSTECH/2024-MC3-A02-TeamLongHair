//
//  FloatingPanelView.swift
//  TeamLongHair
//
//  Created by 김유빈 on 7/26/24.
//

import SwiftUI

struct FloatingPanelView: View {
    @Environment(AppState.self) var appState: AppState
    @State private var panelTitleText = ""
    @State private var panelURLText = ""

    var body: some View {
        @Bindable var appState = appState
        
        Button("Present panel") {
            appState.isPanelPresented.toggle()
        }
        .floatingPanel(isPresented: $appState.isPanelPresented) {
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
