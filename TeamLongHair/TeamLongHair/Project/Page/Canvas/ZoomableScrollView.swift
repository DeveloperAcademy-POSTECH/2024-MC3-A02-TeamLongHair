//
//  ZoomableScrollView.swift
//  TeamLongHair
//
//  NSScrollView의 네이티브 magnification으로 피그마식 줌/팬을 제공한다.
//  줌 중심점·관성·제스처 충돌 처리는 전부 AppKit에 위임.
//

import AppKit
import SwiftUI

struct ZoomableScrollView<Content: View>: NSViewRepresentable {
    @Binding var magnification: CGFloat
    @ViewBuilder var content: () -> Content

    init(magnification: Binding<CGFloat>, @ViewBuilder content: @escaping () -> Content) {
        self._magnification = magnification
        self.content = content
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 0.25
        scrollView.maxMagnification = 3.0
        scrollView.drawsBackground = false

        let hostingView = NSHostingView(rootView: content())
        // 문서 뷰 크기를 SwiftUI 콘텐츠의 fitting size로 명시 지정한다.
        // sizingOptions(.intrinsicContentSize)만으로는 NSScrollView 문서 뷰 frame이
        // 0으로 남아 아무것도 그려지지 않는 문제가 있어 직접 관리한다.
        hostingView.frame = CGRect(origin: .zero, size: hostingView.fittingSize)
        scrollView.documentView = hostingView

        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.boundsDidChange),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
        context.coordinator.scrollView = scrollView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        if let hostingView = scrollView.documentView as? NSHostingView<Content> {
            hostingView.rootView = content()
            // 콘텐츠(노드 수)가 바뀌면 문서 크기도 따라가도록 갱신
            hostingView.frame.size = hostingView.fittingSize
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(magnification: $magnification)
    }

    final class Coordinator: NSObject {
        @Binding var magnification: CGFloat
        weak var scrollView: NSScrollView?

        init(magnification: Binding<CGFloat>) {
            self._magnification = magnification
        }

        @objc func boundsDidChange() {
            guard let scrollView else { return }
            let current = scrollView.magnification
            if abs(magnification - current) > 0.001 {
                // 뷰 업데이트 중 상태 변경 경고를 피하기 위해 다음 런루프에서 반영
                DispatchQueue.main.async { self.magnification = current }
            }
        }

        deinit { NotificationCenter.default.removeObserver(self) }
    }
}
