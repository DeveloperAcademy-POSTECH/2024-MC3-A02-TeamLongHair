//
//  BrowserTabReader.swift
//  TeamLongHair
//
//  프론트모스트 브라우저의 활성 탭 URL/제목을 AppleScript로 읽는다.
//  실패(미지원 브라우저·권한 거부)하면 nil — 수동 입력이 폴백.
//

import AppKit

enum BrowserTabReader {
    struct TabInfo: Equatable {
        let url: String
        let title: String
    }

    private static let safariBundleIDs: Set<String> = ["com.apple.Safari"]
    private static let chromiumBundleIDs: Set<String> = [
        "com.google.Chrome",
        "company.thebrowser.Browser", // Arc
        "com.naver.whale",
    ]

    static func readActiveTab() -> TabInfo? {
        guard let frontmost = NSWorkspace.shared.frontmostApplication,
              let bundleID = frontmost.bundleIdentifier
        else { return nil }

        let source: String
        if safariBundleIDs.contains(bundleID) {
            source = """
            tell application id "\(bundleID)"
                set theURL to URL of front document
                set theTitle to name of front document
                return theURL & "\\n" & theTitle
            end tell
            """
        } else if chromiumBundleIDs.contains(bundleID) {
            source = """
            tell application id "\(bundleID)"
                set theURL to URL of active tab of front window
                set theTitle to title of active tab of front window
                return theURL & "\\n" & theTitle
            end tell
            """
        } else {
            return nil
        }

        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let result = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            debugPrint("BrowserTabReader error:", errorInfo)
            return nil
        }
        guard let combined = result.stringValue else { return nil }
        let parts = combined.components(separatedBy: "\n")
        guard parts.count >= 2, !parts[0].isEmpty else { return nil }
        return TabInfo(url: parts[0], title: parts[1...].joined(separator: " "))
    }
}
