//
//  MenuBarPanelView.swift
//  TeamLongHair
//
//  메뉴바 아이콘 클릭 시 뜨는 팝오버. 드롭존 + 현재 대상 미리보기 + 앱 열기.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct MenuBarPanelView: View {
    var onOpenApp: () -> Void

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TeamLongHair")
                .font(.system(size: 14, weight: .bold))

            // 드롭존
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                .foregroundStyle(isTargeted ? Color.purple400 : Color.lbQuaternary)
                .frame(height: 96)
                .overlay {
                    VStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 20))
                        Text("여기로 브라우저 탭을 끌어놓으세요")
                            .font(.system(size: 12))
                            .foregroundStyle(.lbTertiary)
                    }
                }
                .background(isTargeted ? Color.purple400.opacity(0.08) : .clear)
                .onDrop(of: [.url, .text], isTargeted: $isTargeted) { providers in
                    DroppedURLLoader.load(from: providers) { urls in ingest(urls) }
                    return true
                }

            // 현재 대상 미리보기
            HStack(spacing: 4) {
                Image(systemName: "arrow.turn.down.right")
                    .font(.system(size: 11))
                    .foregroundStyle(.lbTertiary)
                Text(CaptureTarget.targetDescription(appState: appState, context: context))
                    .font(.system(size: 12))
                    .foregroundStyle(.lbSecondary)
                    .lineLimit(1)
            }

            // 최근 수집 확인
            if let receipt = appState.lastIngest {
                Text("\(receipt.count)개 링크를 '\(receipt.targetName)'에 추가")
                    .font(.system(size: 11))
                    .foregroundStyle(.green)
                    .lineLimit(2)
            }

            Divider()

            Button {
                onOpenApp()
            } label: {
                HStack {
                    Image(systemName: "macwindow")
                    Text("앱 열기")
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(width: 300)
    }

    private func ingest(_ urls: [URL]) {
        guard !urls.isEmpty,
              let page = CaptureTarget.resolvePage(appState: appState, context: context) else { return }
        let name = CaptureTarget.targetDescription(appState: appState, context: context)
        let count = LinkIngest.addLinks(urls, to: page)
        appState.lastIngest = IngestReceipt(count: count, targetName: name)
    }
}
