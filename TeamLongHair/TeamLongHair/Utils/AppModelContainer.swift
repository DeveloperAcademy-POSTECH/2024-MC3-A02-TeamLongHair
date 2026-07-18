//
//  AppModelContainer.swift
//  TeamLongHair
//
//  앱 전체가 공유하는 단일 ModelContainer. App과 AppDelegate(메뉴바)가 같은 인스턴스를
//  써야 메뉴바 드롭이 열려 있는 창에 즉시 반영된다.
//

import SwiftData

enum AppModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([Project.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
