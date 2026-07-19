//
//  PermissionStatusView.swift
//  TeamLongHair
//
//  권한 상태를 보여주고 시스템 설정 이동을 돕는 재사용 뷰,
//  그리고 첫 실행 온보딩 시트.
//

import SwiftUI

/// 자동화 권한의 상태와 조치 버튼을 보여준다. 설정 화면과 온보딩에서 공용.
struct PermissionStatusView: View {
    @State private var manager = PermissionManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            permissionRow(
                title: "자동화 (브라우저 제어)",
                reason: "현재 탭의 주소·제목을 자동으로 가져오기 위해 필요합니다. 처음 저장할 때 허용 창이 뜹니다.",
                state: .info
            ) {
                Button("설정 열기") { manager.openAutomationSettings() }
            }
        }
    }

    private enum PermissionState { case info }

    @ViewBuilder
    private func permissionRow(
        title: String,
        reason: String,
        state: PermissionState,
        @ViewBuilder actions: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                statusIcon(state)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
            }
            Text(reason)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                actions()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 10).fill(.bgSecondary)
        }
    }

    @ViewBuilder
    private func statusIcon(_ state: PermissionState) -> some View {
        switch state {
        case .info:
            Image(systemName: "info.circle.fill").foregroundStyle(.secondary)
        }
    }
}

/// 첫 실행 시 앱 소개 + 권한 안내를 보여주는 시트.
struct PermissionOnboardingSheet: View {
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("환영합니다 👋")
                    .font(.title2.bold())
                Text("웹서핑 중 열어둔 탭들을 단축키로 저장하고, 노드로 위계를 만들어 한눈에 관리하세요.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("탭 자동 저장을 쓰려면 아래 권한이 필요합니다:")
                .font(.system(size: 13, weight: .medium))

            PermissionStatusView()

            HStack {
                Spacer()
                Button("시작하기") { onDone() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 440)
    }
}
