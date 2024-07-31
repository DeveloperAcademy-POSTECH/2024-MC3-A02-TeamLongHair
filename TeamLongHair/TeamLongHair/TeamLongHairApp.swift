//
//  TeamLongHairApp.swift
//  TeamLongHair
//
//  Created by Lee Sihyeong on 7/25/24.
//

import SwiftData
import SwiftUI

@main
struct TeamLongHairApp: App {
    var body: some Scene {
        WindowGroup {
            CanvasView()
        }
        .modelContainer(for: Project.self)
    }
}
