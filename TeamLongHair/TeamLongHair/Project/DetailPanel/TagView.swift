//
//  TagView.swift
//  TeamLongHair
//
//  Created by 김준수(엘빈) on 8/2/24.
//
import SwiftUI

struct TagView: View {
    var detail: LinkDetail
    
    @State private var isShowingTagInput: Bool = false
    @State private var tagTextFeild: String = ""
    @State private var tags: [String] = []
    @State private var selectedTags: [String] = []

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("Tag")
                    .font(Font.custom("Pretendard", size: 14))
                    .foregroundColor(Color.lbPrimary)
                
                Spacer()
            }

            HStack(spacing: 8) {
                if !detail.tags.isEmpty {
                    ForEach(detail.tags, id: \.self) { tag in
                        TagButton(tag: tag) {
                            self.detail.tags.removeAll { $0 == tag }
                        }
                    }
                } else {
                    Text("문서에 적합한 태그를 달아보세요")
                        .font(Font.custom("Pretendard", size: 12))
                        .foregroundColor(.lbTertiary)
                }
            }
            
            if isShowingTagInput {
                VStack(alignment: .leading) {
                    TextField("문서에 적합한 태그를 선택하거나 입력해보세요.", text: $tagTextFeild, onCommit: addTag)
                        .font(Font.custom("Pretendard", size: 12))
                        .textFieldStyle(.plain)
                        .foregroundStyle(.lbTertiary)
                        .padding(8)
                        .background {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray100, lineWidth: 1)
                                .foregroundColor(.white000)
                            }
                    
                    ForEach(detail.tags, id: \.self) { tag in
                        HStack {
                            CheckBoxView(isChecked: Binding(
                                get: { self.selectedTags.contains(tag) },
                                set: { isChecked in
                                    if isChecked {
                                        self.selectTag(tag)
                                    } else {
                                        self.selectedTags.removeAll { $0 == tag }
                                    }
                                }
                            ))
                            
                            TagButton(tag: tag, isShowingXmark: true) {
                                self.tags.removeAll { $0 == tag }
                            }
                        }
                    }
                }
//                .padding()
            }
        }
        .padding(.horizontal, 16)
        .frame(width: 300)
        .onTapGesture {
            withAnimation {
                if isShowingTagInput {
                    self.isShowingTagInput = false
                } else {
                    self.isShowingTagInput = true
                }
            }
        }
        .onChange(of: selectedTags) {
            detail.tags = selectedTags
        }
    }
    
    private func addTag() {
        if !tagTextFeild.isEmpty && tagTextFeild.count <= 5 {
            detail.tags.append(tagTextFeild)
//            tags.append(tagTextFeild)
            self.tagTextFeild = ""
        }
    }
    
    private func selectTag(_ tag: String) {
        if selectedTags.count < 3 {
            selectedTags.append(tag)
        }
    }
}

struct CheckBoxView: View {
    @Binding var isChecked: Bool
    let customColor = Color.purple500
    
    var body: some View {
        Button {
            self.isChecked.toggle()
        } label: {
            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(isChecked ? customColor : .gray)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}

struct TagButton: View {
    var tag: String
    var isShowingXmark = false
    var action: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(Font.custom("Pretendard", size: 14))
            
            if isShowingXmark {
                Button(action: action) {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .foregroundColor(.lbSecondary)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.gray050)
        .cornerRadius(4)
    }
}
