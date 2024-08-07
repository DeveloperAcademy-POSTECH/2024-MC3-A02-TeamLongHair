//
//  IconEnums.swift
//  test
//
//  Created by 김준수(엘빈) on 8/6/24.
//

import SwiftUI

enum Icon: String, CaseIterable, Codable {
    case codesnippet, curlybraces, bug, git, framework, cloud, forum, video, tutorial, Document
    
    func imageName(color: IconColor) -> String {
        return "\(self.rawValue)_\(color.rawValue)"
    }
}

enum IconColor: String, CaseIterable, Codable {
    case gray, red, orange, yellow, green, sky, blue, purple, plum
    
    func returnColor() -> Color {
        switch self {
        case .gray:
                .gray100
        case .red:
                .nodeRed
        case .orange:
                .nodeOrange
        case .yellow:
                .nodeYellow
        case .green:
                .nodeGreen
        case .sky:
                .nodeSky
        case .blue:
                .nodeBlue
        case .purple:
                .nodePurple
        case .plum:
                .nodePlum
        }
    }
}
