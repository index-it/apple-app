//
//  ListEditor.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 19/11/24.
//

import IxCoreKit
import MCEmojiPicker
import SwiftUI

struct ListEditor: View {
    @Environment(\.showPaywall) private var showPaywall
    @Binding var isPresented: Bool
    private var addingNew: Bool

    @AppStorage(AppStorageKeys.loggedInUser) private var user: User?

    @State private var showEmojiPicker = false
    @FocusState private var isNameFocused: Bool

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
        isPresented: Binding<Bool>,
        addingNew: Bool = true,
        name: String,
        color: Color,
        emoji: String,
        isPublic: Bool,
        colors: [Color],
        onSave: @escaping (_ name: String, _ color: Color, _ icon: String, _ isPublic: Bool) -> Void
    ) {
        _isPresented = isPresented
        self.addingNew = addingNew

        self.name = name
        self.color = color
        self.emoji = emoji
        self.isPublic = isPublic
        self.colors = colors

        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    ListCard(
                        list: IxList.mock(name: name.isEmpty ? "List name" : name, emoji: emoji, color: color.hexString),
                        owner: false,
                        onTap: {},
                        onShare: {},
                        onEdit: {},
                        onArchiveToggle: {},
                        onDelete: {},
                        onLeave: {},
                        withInteractions: false
                    )
                    .frame(maxWidth: 200)
                    .padding()

                    Spacer()
                        .frame(height: 20)

                    HStack(spacing: 12) {
                        Button {
                            isNameFocused = false
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

                        TextField("List name", text: $name)
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
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(.background))
                .padding()

                Section {
                    ColorSelector(color: $color, colors: colors)
                        .padding()
                }
                .background(RoundedRectangle(cornerRadius: 12).fill(.background))
                .padding()

                Form {
                    Section {
                        Toggle("Public", isOn: Binding(
                            get: { isPublic },
                            set: { newValue in
                                let hasPro = user?.has_pro == true

                                if hasPro || !IxFlags.Pro.enabled {
                                    isPublic = newValue
                                } else {
                                    showPaywall()
                                }
                            }
                        ))
                    } header: {
                        Text("Visibility")
                    } footer: {
                        Text("By making the list public anyone with a link to it will be able to see it but not modify it.")
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationTitle(addingNew ? "Add List" : "Edit List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isPresented = false
                    } label: {
                        Text("Cancel")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onSave(name, color, emoji, isPublic)
                        isPresented = false
                    } label: {
                        Text("Save")
                    }.disabled(isNameInvalid)
                }
            }
            .onAppear {
                if addingNew {
                    isNameFocused = true
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true

    ListEditor(
        isPresented: $isPresented,
        name: "",
        color: Color.accentColor,
        emoji: "",
        isPublic: false,
        colors: []
    ) { _, _, _, _ in
    }
}
