////
////  RightPanelView.swift
////  TeamLongHair
////
////  Created by 김준수(엘빈) on 8/1/24.
////
//
//import SwiftUI
//
//struct RightPanelView2: View {
//    
//    @State private var textFieldLink: String = "기본링크"
//    @State private var textEditorMemo: String = ""
//    @State private var textEditorCode: String = ""
//   
//    @State private var hoveredIndex: Int? = nil
//    @State private var selectedIndex: Int? = nil
//    let colors: [Color] = [.black, .red, .orange, .yellow, .green, .blue, .indigo, .purple]
//
//  
//    var body: some View {
//        ScrollView{
//            
//            VStack{
//                
//                VStack {
//                    HStack {
//                        Image(systemName: "folder.fill")
//                            .frame(width: 32, height: 32)
//                            .padding(6)
//                        //아이콘 확정후 변경예정
//                        Text("PencilKit 공식 문서")
//                            .font(
//                                Font.custom("Pretendard", size: 16)
//                                    .weight(.bold)
//                            )
//                            .foregroundColor(.gray900)
//                        //데이터 받아오기
//                        Spacer()
//                        Button(action: {
//                            
//                        }
//                               , label: {
//                            Image(systemName: "square.and.arrow.up")
//                            
//                        }).buttonStyle(PlainButtonStyle())
//                        .frame(width: 32, height: 32)
//                            .padding(12)
//                        
//                    }
//                    //아이콘 확정 후 변경예정
//                    
//                    
//                    TextField("", text: $textFieldLink)
//                        .frame(height: 30)
//                        .font(Font.custom("Pretendard", size: 12))
//                        .overlay {
//                                       RoundedRectangle(cornerRadius: 5)
//                                           .stroke(
//                                            Color(.gray100),
//                                               lineWidth: 1
//                                           )
//                                   }
//                        .foregroundColor(.gray900)
//                        .textFieldStyle(.roundedBorder)
//                        .padding(8)
//                    
//                        
//                }.frame(width: 300,height: 118)
//                
//                Divider()
//                Text("Tag")
//                    .font(
//                    Font.custom("Pretendard", size: 16)
//                    .weight(.bold)
//                    )
//                    .foregroundColor(.gray900)
//                    .padding(12)
//                    .frame(width: 300, alignment: .leading)
//                
//                Divider()
//                Text("Color")
//                    .font(
//                    Font.custom("Pretendard", size: 16)
//                    .weight(.bold)
//                    )
//                    .foregroundColor(.gray900)
//                    .padding(12)
//                    .frame(width: 300, alignment: .leading)
//                HStack{
//                    //여기에 컬러 버튼 추가
//                    HStack {
//                               ForEach(colors.indices, id: \.self) { index in
//                                   ColorCircleView(
//                                       color: colors[index],
//                                       isSelected: selectedIndex == index,
//                                       onHover: { hovering in
//                                           if hovering {
//                                               hoveredIndex = index
//                                           } else if hoveredIndex == index {
//                                               hoveredIndex = nil
//                                           }
//                                       },
//                                       onClick: {
//                                           if selectedIndex == index {
//                                               selectedIndex = nil
//                                           } else {
//                                               selectedIndex = index
//                                           }
//                                       }
//                                   )
//                                   .overlay(
//                                       Circle()
//                                           .stroke(Color.gray, lineWidth: hoveredIndex == index ? 2 : 0)
//                                           .frame(width: 24, height: 24)
//                                   )
//                               }
//                           }
//                }
//                Divider()
//                Text("Memo")
//                    .font(
//                    Font.custom("Pretendard", size: 16)
//                    .weight(.bold)
//                    )
//                    .foregroundColor(.gray900)
//                    .padding(12)
//                    .frame(width: 300, alignment: .leading)
//                TextEditor(text: $textEditorMemo)
//                            .frame(width: 276, height: 108)
//                            .cornerRadius(5)
//                            .padding(11)
//                            .font(Font.custom("Pretendard", size: 13))
//                            .foregroundColor(.gray900)
//                
//                Divider()
//                
//                HStack {
//                    Text("Code")
//                        .font(
//                        Font.custom("Pretendard", size: 16)
//                        .weight(.bold)
//                        )
//                        .foregroundColor(.gray900)
//                        .padding(12)
//                    Spacer()
//                    Button(action: {
//                        
//                    }  , label: {
//                        Image(systemName: "doc.on.doc")
//                            .frame(width: 32, height: 32)
//                            .padding(6)
//                        
//                    }).buttonStyle(PlainButtonStyle())
//                    
//                   
//                    
//                }
//                
//                TextEditor(text: $textEditorCode)
//                    .frame(width: 276)
//                    .frame(minHeight: 108)
//                    .cornerRadius(5)
//                    .padding(11)
//                    .font(Font.custom("Pretendard", size: 13))
//                    .foregroundColor(.gray900)
//                
//                
//                
//            }
//        }.frame(width: 300,height: 834)
//    }
//}
//
//#Preview {
//    RightPanelView2()
//}
