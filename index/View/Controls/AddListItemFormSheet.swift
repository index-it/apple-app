//
//  AddListItemFormSheet.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import SwiftUI
import SwiftData
import IxCoreKit

struct AddListItemFormSheet: View {
    @ForcedEnvironment(\.ixApiClient) private var ixApiClient
    @Environment(\.modelContext) private var context

    @State private var name: String
    @State private var link: String
    @State private var note: String = ""
    @State private var selectedListId: String
    @State private var selectedCategoryId: String?

    private var onCancel: () -> Void
    private var syncThreeshold: Int64

    @Query private var lists: [IxList]
    @Query private var categories: [IxListCategory]

    init(
        name: String? = nil,
        link: String? = nil,
        note: String? = nil,
        selectedListId: String? = nil,
        selectedCategoryId: String? = nil,
        onCancel: @escaping () -> Void,
        syncThreeshold: Int64 = 3600000
    ) {
        self.name = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.link = link?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.note = note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.selectedListId = selectedListId ?? ""
        self.selectedCategoryId = selectedCategoryId
        self.onCancel = onCancel
        self.syncThreeshold = syncThreeshold
    }

    private func fetchLists() async {
        do {
            let lists = try await ixApiClient.getLists()

            try context.transaction {
                try context.delete(model: IxList.self)

                lists.forEach { ixList in
                    context.insert(ixList)
                }
            }

            
        } catch {}
    }

    private func fetchCategories(listId: String) async {
        do {
            let categories = try await ixApiClient.getListCategories(listId: listId)

            try context.transaction {
                try context.delete(
                    model: IxListCategory.self,
                    where: #Predicate { category in
                        category.listId == listId
                    }
                )

                categories.forEach { category in
                    context.insert(category)
                }
            }
        } catch {}
    }

    private func save(
        listId: String,
        categoryId: String?,
        name: String,
        link: String?,
        note: String?
    ) async {
        do {
            let item = try await ixApiClient.createListItem(listId: listId, categoryId: categoryId, name: name, link: link, note: note)

            Task { @MainActor in
                do {
                    try context.transaction {
                        context.insert(item)
                    }
                } catch {}
            }

            onCancel()
        } catch {
            onCancel()
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name, axis: .vertical)

                    TextField("Link", text: $link, axis: .vertical)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Notes", text: $note, axis: .vertical)
                        .lineLimit(3...)
                }

                Section {
                    if !lists.isEmpty {
                        Picker(selection: $selectedListId) {
                            ForEach(lists.sorted{ $0.name < $1.name }, id: \.id) { list in
                                Text("\(list.icon)  \(list.name)")
                                    .tag(list.id)
                            }
                        } label: {
                            Text("List")
                        }
                        .pickerStyle(.menu)
                    }

                    Picker(selection: $selectedCategoryId) {
                        Text("No category").tag(nil as String?)

                        ForEach(categories.filter { cat in cat.listId == selectedListId }.sorted{ $0.name < $1.name }, id: \.id) { category in
                            Text(category.name).tag(category.id)
                        }
                    } label: {
                        Text("Category")
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Save to list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let link = link.isEmpty ? nil : link
                        let note = note.isEmpty ? nil : note

                        Task {
                            await save(listId: selectedListId, categoryId: selectedCategoryId, name: name, link: link, note: note)
                        }
                    }.disabled(name.isEmpty)
                }
            }
        }
        .onAppear {
            Task {
                if await SyncRegister.shared.hasExpired(SyncResource.lists, threshold: syncThreeshold) {
                    await fetchLists()
                }
            }
        }
        .onChange(of: lists, { _, newValue in
            if selectedListId.isEmpty, let listId = newValue.first?.id {
                selectedListId = listId
            }
        })
        .onChange(of: selectedListId) { _, newValue in
            selectedCategoryId = nil

            Task {
                if await SyncRegister.shared.hasExpired(SyncResource.list(newValue), threshold: syncThreeshold) {
                    await fetchCategories(listId: newValue)
                }
            }
        }
    }
}
