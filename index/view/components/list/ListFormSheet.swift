//
//  ListFormSheet.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 19/11/24.
//

import SwiftUI
import MCEmojiPicker

struct ListFormSheet: View {
    @Binding var showSheet: Bool
    
    @State private var showEmojiPicker = false
    @FocusState private var isNameFocused: Bool
    
    @State private var namePlaceholder: String
    @State private var name: String
    @State private var color: Color
    @State private var emoji: String
    @State private var isPublic: Bool
    
    private var isNameInvalid: Bool {
        name.isEmpty || name.count >= 100
    }

    private var onSave: (_ name: String, _ color: Color, _ icon: String, _ isPublic: Bool) -> Void
    
    init(
        showSheet: Binding<Bool>,
        name: String,
        color: Color,
        emoji: String,
        isPublic: Bool,
        namePlaceholder: String,
        onSave: @escaping (_ name: String, _ color: Color, _ icon: String, _ isPublic: Bool) -> Void
    ) {
        self._showSheet = showSheet
        
        self.name = name
        self.color = color
        self.emoji = emoji
        self.isPublic = isPublic
        self.namePlaceholder = namePlaceholder
        
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    ListCard(list: IxList.loading(name: name.isEmpty ? namePlaceholder : name, emoji: emoji, color: color.hexString()), onTap: {}, onShare: {}, onEdit: {}, onDelete: {}, withInteractions: false)
                        .frame(maxWidth: 200)
                        .padding()
                    
                    Spacer()
                        .frame(height: 20)
                    
                    TextField(namePlaceholder, text: $name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .focused($isNameFocused)
                        .onTapGesture {
                            isNameFocused = true
                        }
                        .padding()
                        .background(isNameFocused ? .quaternary : .quinary)
                        .clipShape(.buttonBorder)
                    
                }.padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(.background))
                    .padding()
                
                Form {
                    Section("Details") {
                        ColorPicker("Color", selection: $color)
                        Button {
                            showEmojiPicker = true
                        } label: {
                            HStack {
                                Text("Emoji")
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text(emoji)
                                    .font(.title2)
                            }
                        }.emojiPicker(
                            isPresented: $showEmojiPicker,
                            selectedEmoji: $emoji,
                            arrowDirection: .down
                        )
                        
                        Toggle("Public", isOn: $isPublic)
                    }
                }
                
            }
            .background(Color(UIColor.systemGroupedBackground))
                .frame(maxHeight: .infinity, alignment: .top)
                .navigationTitle("New list")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showSheet = false
                        } label: {
                            Text("Cancel")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            onSave(name, color, emoji, isPublic)
                            showSheet = false
                        } label: {
                            Text("Save")
                        }.disabled(isNameInvalid)
                    }
                }
                .onAppear {
                    isNameFocused = true
                }
        }
    }
}

#Preview {
    @Previewable @State var show = true

    ListFormSheet(
        showSheet: $show,
        name: "",
        color: Color.cyan,
        emoji: String.randomEmoji(),
        isPublic: false,
        namePlaceholder: "List name"
    ) { name, color, emoji, isPublic in
        
    }
}
