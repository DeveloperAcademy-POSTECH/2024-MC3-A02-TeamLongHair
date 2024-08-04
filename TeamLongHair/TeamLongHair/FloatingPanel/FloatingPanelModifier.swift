//
//  FloatingPanelModifier.swift
//  TeamLongHair
//
//  Created by Damin on 7/28/24.
//

import SwiftUI
 
struct FloatingPanelModifier<PanelContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    var contentRect: CGRect = CGRect(x: 0, y: 0, width: 624, height: 512)
    @ViewBuilder let view: () -> PanelContent
    @State var panel: FloatingPanel<PanelContent>?

    func body(content: Content) -> some View {
        content
            .onAppear {
                panel = FloatingPanel(view: view, contentRect: contentRect, isPresented: $isPresented)
                if isPresented {
                    present()
                }
            }.onDisappear {
                panel?.close()
                panel = nil
            }.onChange(of: isPresented) { _, value in
                if value {
                    present()
                } else {
                    panel?.close()
                }
            }
    }
    
    func present() {
        NSApp.activate(ignoringOtherApps: true)
        panel?.center()
        panel?.makeKeyAndOrderFront(nil)
    }
}

