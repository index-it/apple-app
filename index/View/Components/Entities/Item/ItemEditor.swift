//
//  ItemEditor.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 15/12/24.
//

import IxCoreKit
import SwiftUI

private enum FocusField: Hashable {
    case name
    case link
    case note
}

struct ItemEditor: View {
    @FocusState private var focusField: FocusField?

    @Binding private var config: EditorConfig<IxListItem>
    private var onCancel: () -> Void
    private var onSave: () -> Void

    private var categories: [IxListCategory]

    private var item: IxListItem {
        return config.entity
    }

    init(
        config: Binding<EditorConfig<IxListItem>>,
        categories: [IxListCategory],
        onCancel: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) {
        _config = config
        self.categories = categories.sorted {
            $0.name < $1.name
        }
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    TextField("Name", text: $config.entity.name)
                        .focused($focusField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit {
                            focusField = .link
                        }

                    Section {
                        Picker("Category", selection: $config.entity.categoryId) {
                            Text("No category").tag(nil as String?)

                            ForEach(categories, id: \.id) { category in
                                Text(category.name).tag(category.id)
                            }
                        }
                        .pickerStyle(.menu)

                        TextField("Link", text: $config.entity.link ?? "", axis: .vertical)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusField, equals: .link)
                            .submitLabel(.next)
                            .onSubmit {
                                focusField = .note
                            }

                        TextField("Notes", text: $config.entity.note ?? "", axis: .vertical)
                            .lineLimit(3...)
                            .focused($focusField, equals: .note)
                            .submitLabel(.done)
                            .onSubmit {
                                onSave()
                            }
                    } header: {
                        Text("Properties")
                    } footer: {
                        Text("All properties are optional")
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationTitle(config.mode == .create ? "Add Item" : "Edit Item")
            .navigationSubtitle(config.multi ? "Adding multiple items" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onSave()
                    } label: {
                        if config.loading {
                            ProgressView()
                        } else {
                            Label("Save", systemImage: "checkmark")
                        }
                    }
                    .disabled(!config.entity.validationRes.isSuccess)
                }
            }
            .onAppear {
                if config.mode == .create {
                    focusField = .name
                }
            }
        }
    }
}

#Preview {
//    @Previewable @State var isPresented = false
//
//    ItemEditor(
//        isPresented: $isPresented,
//        addingNew: true,
//        name: "",
//        categoryId: nil,
//        link: nil,
//        note: nil,
//        categories: []
//    ) { name, categoryId, link, note in
//
//    }
}
