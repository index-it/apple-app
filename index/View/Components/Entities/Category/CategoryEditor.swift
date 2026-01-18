//
//  CategoryEditor.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/12/24.
//

import IxCoreKit
import SwiftUI

struct CategoryEditor: View {
    @FocusState private var isNameFocused: Bool
    @Binding var config: EditorConfig<IxListCategory>

    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    TextField("Name", text: $config.entity.name)
                        .focused($isNameFocused)

                    Section {
                        Toggle("Use list color", isOn: Binding(
                            get: { config.entity.color == nil },
                            set: { _ in config.entity.color = ColorHelper.randomIxColor().hexString }
                        ))

                        if config.entity.color != nil {
                            ColorSelector(
                                color: Binding(
                                    get: {
                                        config.entity.color?.toColor() ?? ColorHelper.randomIxColor()
                                    },
                                    set: {
                                        value in config.entity.color = value.hexString
                                    }
                                ),
                                colors: ColorHelper.ixColors
                            )
                        }
                    } header: {
                        Text("Color")
                    } footer: {
                        Text(config.entity.color == nil ?
                            "The color of the category will be the same as the one of the list" :
                            "Scroll horizontally for more colors"
                        )
                    }
                }
                .animation(.default, value: config.entity.color)
            }
            .background(Color.systemGroupedBackground)
            .navigationTitle(config.mode == .create ? "Add Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onSave()
                    } label: {
                        if config.loading {
                            ProgressView()
                        } else {
                            Label("Save", systemImage: "checkmark")
                                .labelStyle(.titleOnly)
                        }
                    }
                    .disabled(!config.entity.validationRes.isSuccess)
                }
            }
            .onAppear {
                if config.mode == .create {
                    isNameFocused = true
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var config = EditorConfig<IxListCategory>()

    CategoryEditor(
        config: $config,
        onCancel: {}
    ) {
        // action
    }
}
