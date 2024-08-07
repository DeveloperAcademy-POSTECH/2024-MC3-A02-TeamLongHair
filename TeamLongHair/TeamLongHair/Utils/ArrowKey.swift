//
//  ArrowKey.swift
//  TeamLongHair
//
//  Created by Damin on 8/6/24.
//

import Foundation

enum ArrowKey: CaseIterable {
    case up, down, left, right

    var key: Int {
        switch self {
        case .up: return 126
        case .down: return 125
        case .right: return 124
        case .left: return 123
        }
    }
}
