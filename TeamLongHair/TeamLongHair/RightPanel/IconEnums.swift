//
//  IconEnums.swift
//  test
//
//  Created by 김준수(엘빈) on 8/6/24.
//

import SwiftUI

enum Icon: String, CaseIterable {
    case codesnippet, curlybraces, bug, git, framework, cloud, forum, video, tutorial, Document
    
    func imageName(color: IconColor) -> String {
        return "\(self.rawValue)_\(color.rawValue)"
    }
}

enum IconColor: String, CaseIterable {
    case gray, red, orange, yellow, green, sky, blue, purple, plum
}
