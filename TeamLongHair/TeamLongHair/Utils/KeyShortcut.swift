//
//  KeyShortCut.swift
//  TeamLongHair
//
//  Created by Damin on 7/31/24.
//

import AppKit

struct KeyShortcut: Equatable {
    var modifierFlags: NSEvent.ModifierFlags
    var keyCode: Int
    
    init(modifierFlags: NSEvent.ModifierFlags, keyCode: Int) {
        self.modifierFlags = modifierFlags
        self.keyCode = keyCode
    }
    
    var description: String {
        var parts: [String] = []
        
        if modifierFlags.contains(.command) {
            parts.append("⌘")
        }
        if modifierFlags.contains(.option) {
            parts.append("⌥")
        }
        if modifierFlags.contains(.shift) {
            parts.append("⇧")
        }
        if modifierFlags.contains(.control) {
            parts.append("⌃")
        }
        
        parts.append(keyCodeToString(keyCode))
        
        return parts.joined(separator: " ")
    }

    private func keyCodeToString(_ keyCode: Int) -> String {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 36: return "Return"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 48: return "Tab"
        case 49: return "Space"
        case 50: return "`"
        case 51: return "Delete"
        case 52: return "Enter"
        case 53: return "⎋" // Escape
        case 65: return "."
        case 67: return "*"
        case 69: return "+"
        case 71: return "Clear"
        case 75: return "/"
        case 76: return "Enter"
        case 78: return "-"
        case 81: return "="
        case 82: return "0"
        case 83: return "1"
        case 84: return "2"
        case 85: return "3"
        case 86: return "4"
        case 87: return "5"
        case 88: return "6"
        case 89: return "7"
        case 91: return "8"
        case 92: return "9"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 99: return "F3"
        case 100: return "F8"
        case 101: return "F9"
        case 103: return "F11"
        case 105: return "F13"
        case 106: return "F14"
        case 107: return "F10"
        case 109: return "F12"
        case 111: return "F15"
        case 113: return "Help"
        case 114: return "Home"
        case 115: return "PageUp"
        case 116: return "ForwardDelete"
        case 117: return "F4"
        case 118: return "End"
        case 119: return "F2"
        case 120: return "PageDown"
        case 121: return "F1"
        case 122: return "LeftArrow"
        case 123: return "RightArrow"
        case 124: return "DownArrow"
        case 125: return "UpArrow"
        default: return "?"
        }
    }
}
