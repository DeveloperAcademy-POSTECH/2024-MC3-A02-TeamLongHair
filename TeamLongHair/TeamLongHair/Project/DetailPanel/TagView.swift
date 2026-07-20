//
//  TagView.swift
//  TeamLongHair
//

import SwiftUI

/// 링크에 붙이는 태그. `detail.tags`를 직접 읽고 쓴다 —
/// 별도 @State로 복제하면 링크를 바꿀 때 이전 링크의 태그가 새 링크에 덮어써진다.
struct TagView: View {
    var detail: LinkDetail

    /// 노드 카드가 최대 3개까지 보여주므로 여기서도 3개로 제한한다.
    private let maxTags = 3
    /// 칩이 길어지면 노드에서 잘리므로 짧게 유지한다.
    private let maxTagLength = 5

    @State private var isAdding = false
    @State private var newTag = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: InspectorMetrics.labelGap) {
            SectionLabel("태그")

            HStack(spacing: 6) {
                ForEach(detail.tags, id: \.self) { tag in
                    chip(tag)
                }

                if isAdding {
                    TextField("태그", text: $newTag)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11.5))
                        .foregroundStyle(.lbPrimary)
                        .frame(width: 66)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 7).fill(.gray050))
                        .focused($inputFocused)
                        .onSubmit { commit() }
                        .onExitCommand { cancel() }
                } else if detail.tags.count < maxTags {
                    Button {
                        isAdding = true
                        inputFocused = true
                    } label: {
                        Text("+ 추가")
                            .font(.system(size: 11.5))
                            .foregroundStyle(.lbTertiary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3]))
                                    .foregroundStyle(.gray100)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chip(_ tag: String) -> some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.system(size: 11.5))
                .foregroundStyle(.lbSecondary)
                .lineLimit(1)
            Button {
                detail.tags.removeAll { $0 == tag }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.lbQuaternary)
            }
            .buttonStyle(.plain)
            .help("태그 삭제")
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: 7).fill(.gray050))
    }

    /// 입력을 확정한다. 비었거나 중복이면 그냥 닫는다.
    private func commit() {
        let tag = String(newTag.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxTagLength))
        if !tag.isEmpty, !detail.tags.contains(tag), detail.tags.count < maxTags {
            detail.tags.append(tag)
        }
        cancel()
    }

    private func cancel() {
        newTag = ""
        isAdding = false
        inputFocused = false
    }
}
