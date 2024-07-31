//
//  AppState.swift
//  TeamLongHair
//
//  Created by Damin on 7/31/24.
//

import SwiftUI

@Observable
final class AppState {
    static let shared = AppState()
    var keyCode: Int?
    var modifierFlags: NSEvent.ModifierFlags?
    var isPanelPresented: Bool = false

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(toggleFloatingPanel(_ :)), name: .toggleFloatingPanel, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func toggleFloatingPanel(_ notification: Notification) {
        if let userInfo = notification.userInfo, let shouldPresent = userInfo["shouldPresent"] as? Bool {
            isPanelPresented = shouldPresent
        } else {
            isPanelPresented.toggle()
        }
    }
}
