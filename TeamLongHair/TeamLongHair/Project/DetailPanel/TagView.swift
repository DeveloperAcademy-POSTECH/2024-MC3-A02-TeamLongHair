//
//  TagView.swift
//  TeamLongHair
//
//  Created by 김준수(엘빈) on 8/2/24.
//
import SwiftUI

struct TagView: View {
    var detail: LinkDetail
    @State private var showTagInput: Bool = false
    @State private var newTag: String = ""
    @State private var tags: [String] = []
    @State private var selectedTags: [String] = []

    var body: some View {
        VStack {
            Text("Tag")
                .font(
                    Font.custom("Pretendard", size: 16)
                        .weight(.bold)
                )
                .foregroundColor(Color("lbPrimary"))
                .padding(12)
                .frame(width: 300, alignment: .leading)
            
            if !selectedTags.isEmpty {
                HStack {
                    ForEach(selectedTags, id: \.self) { tag in
                        TagButton(tag: tag, action: {
                            self.selectedTags.removeAll { $0 == tag }
                        })
                        .padding(.vertical, 4)
                    }
                }
            } else {
                Button(action: {
                    withAnimation {
                        self.showTagInput.toggle()
                    }
                }, label: {
                    Text("문서에 적합한 태그를 달아보세요")
                        .foregroundColor(.gray)
                })
                .buttonStyle(PlainButtonStyle())
                .padding()
            }
            
            if showTagInput {
                VStack(alignment: .leading) {
                    TextField("최대 5글자 까지 입력 가능합니다", text: $newTag, onCommit: addTag)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading) {
                        ForEach(tags, id: \.self) { tag in
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
                                TagButton(tag: tag, action: {
                                    self.tags.removeAll { $0 == tag }
                                })
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
        }
        .background(Color.white.opacity(0.001)) // Trick to detect taps outside
        .onTapGesture {
            if showTagInput {
                withAnimation {
                    self.showTagInput = false
                }
            }
        }
        .onChange(of: selectedTags) {
            detail.tags = selectedTags
        }
    }
    
    private func addTag() {
        if !newTag.isEmpty && newTag.count <= 5 {
            tags.append(newTag)
            newTag = ""
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
        Button(action: {
            self.isChecked.toggle()
        }) {
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
    var action: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .foregroundColor(.gray)
                .padding(.leading, 8)
            
            Button(action: action) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(5)
    }
}
