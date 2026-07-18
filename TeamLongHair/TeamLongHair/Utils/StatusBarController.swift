//
//  StatusBarController.swift
//  TeamLongHair
//
//  메뉴바 상주(NSStatusItem). 아이콘에 브라우저 탭을 직접 드롭하면 마지막 본 페이지로
//  수집하고, 클릭하면 팝오버(MenuBarPanelView)를 띄운다. AppDelegate가 소유한다.
//

import AppKit
import SwiftUI

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var dropView: StatusItemDropView?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "point.3.filled.connected.trianglepath.dotted",
                                   accessibilityDescription: "TeamLongHair")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self

            // 버튼 위에 드롭 전용 뷰를 얹어 아이콘 직접 드롭을 받는다.
            let drop = StatusItemDropView(frame: button.bounds)
            drop.autoresizingMask = [.width, .height]
            drop.onDropURLs = { [weak self] urls in self?.ingest(urls) }
            drop.onClick = { [weak self] in self?.togglePopover() }
            button.addSubview(drop)
            dropView = drop
        }

        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPanelView(onOpenApp: { [weak self] in self?.openApp() })
                .environment(AppState.shared)
                .modelContainer(AppModelContainer.shared)
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    /// 팝오버의 "앱 열기" 및 아이콘 클릭에서 메인 창을 앞으로.
    func openApp() {
        popover.performClose(nil)
        NSApp.activate(ignoringOtherApps: true)
        // `FloatingPanel<Content>` is generic, so it can't be used in an unbound `is` check;
        // matching the class name prefix instead lets us exclude it regardless of `Content`.
        let mainWindow = NSApp.windows.first { window in
            window.styleMask.contains(.titled)
                && !NSStringFromClass(type(of: window)).hasPrefix("FloatingPanel")
        }
        mainWindow?.makeKeyAndOrderFront(nil)
    }

    /// 드롭된 URL을 대상 페이지로 수집하고 피드백 신호를 남긴다.
    private func ingest(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        let context = AppModelContainer.shared.mainContext
        guard let page = CaptureTarget.resolvePage(appState: AppState.shared, context: context) else { return }
        let name = CaptureTarget.targetDescription(appState: AppState.shared, context: context)
        let count = LinkIngest.addLinks(urls, to: page)
        AppState.shared.lastIngest = IngestReceipt(count: count, targetName: name)
    }
}

/// 메뉴바 버튼 위에 얹혀 URL/문자열 드롭을 받는 뷰.
final class StatusItemDropView: NSView {
    var onDropURLs: (([URL]) -> Void)?
    var onClick: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.URL, .fileURL, .string])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func mouseDown(with event: NSEvent) { onClick?() }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        var urls: [URL] = []
        if let objects = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
            urls = objects
        }
        if urls.isEmpty, let text = pasteboard.string(forType: .string),
           let url = LinkMetadataParsing.normalizedURL(from: text) {
            urls = [url]
        }
        urls = urls.filter { $0.scheme == "http" || $0.scheme == "https" }
        guard !urls.isEmpty else { return false }
        onDropURLs?(urls)
        return true
    }
}
