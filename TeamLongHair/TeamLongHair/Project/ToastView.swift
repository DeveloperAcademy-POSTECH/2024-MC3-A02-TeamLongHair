//
//  ToastView.swift
//  TeamLongHair
//
//  드롭 수집 결과를 하단에 잠깐 표시하는 토스트.
//

import SwiftUI

struct ToastView: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.lbPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            Capsule().fill(.bgSecondary)
                .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
        }
    }
}
