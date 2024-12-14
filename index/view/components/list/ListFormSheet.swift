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
    private var colors: [Color]
    
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
        colors: [Color],
        onSave: @escaping (_ name: String, _ color: Color, _ icon: String, _ isPublic: Bool) -> Void
    ) {
        self._showSheet = showSheet
        
        self.name = name
        self.color = color
        self.emoji = emoji
        self.isPublic = isPublic
        self.namePlaceholder = namePlaceholder
        self.colors = colors
        
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
                    
                    HStack(spacing: 12) {
                        Button {
                            showEmojiPicker = true
                        } label: {
                            Text(emoji)
                                .font(.title2)
                                .padding()
                                
                        }.background(.quaternary)
                            .clipShape(.circle)
                            .emojiPicker(
                                isPresented: $showEmojiPicker,
                                selectedEmoji: $emoji,
                                arrowDirection: .up
                            )
                        
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
                    }
                    
                }.padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(.background))
                    .padding()
                
                Section {
                    ColorSelector(color: $color, colors: colors)
                }.background(RoundedRectangle(cornerRadius: 12).fill(.background))
                    .padding()
                
                Form {
                    Section() {
                        Toggle("Public", isOn: $isPublic)
                    } header: {
                        Text("Visibility")
                    } footer: {
                        Text("By making the list public anyone with a link to it will be able to see it but not modify it.")
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
        namePlaceholder: "List name",
        colors: [.red, .green, .blue, .yellow, .pink, .purple]
    ) { name, color, emoji, isPublic in
        
    }
}
