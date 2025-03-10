//
//  ShareExtensionView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import SwiftUI

struct ShareExtensionView: View {
    private var ixApiClient = IxApiClient()
    
    @State private var name: String
    @State private var link: String
    @State private var note: String = ""
    
    @State private var loadingLists = false
    @State private var lists: [IxList] = []
    @State private var selectedList: IxList = IxList.loading()
    
    @State private var loadingCategories = false
    @State private var categoriesDict: [String: [IxListCategory]] = [:]
    @State private var categories: [IxListCategory] = []
    @State private var selectedCategory: IxListCategory? = nil
    
    init(name: String?, link: String?) {
        self.name = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.link = link?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    private func loadLists() async {
        do {
            loadingLists = true
            lists = try await ixApiClient.getLists()
            if let list = lists.first {
                selectedList = list
            } else {
                close()
            }
            loadingLists = false
        } catch {
            loadingLists = false
            print(error)
            close()
        }
    }
    
    private func loadCategories(listId: String) async {
        do {
            loadingCategories = true
            if let cats = categoriesDict[listId] {
                categories = cats
            } else {
                let cats = try await ixApiClient.getListCategories(listId: listId)
                categoriesDict[listId] = cats
                categories = cats
            }
            
            loadingCategories = false
        } catch {
            loadingCategories = false
            print(error)
            close()
        }
    }
    
    private func save(listId: String, categoryId: String?, name: String, link: String?, note: String?) async {
        do {
            let _ = try await ixApiClient.createListItem(listId: listId, categoryId: categoryId, name: name, link: link, note: note)
            
            close()
        } catch {
            print(error)
            close()
        }
    }
    
    var body: some View {
        formView
            .onAppear {
                Task {
                    await loadLists()
                }
            }
            .onChange(of: selectedList) { _, newValue in
                Task {
                    selectedCategory = nil
                    await loadCategories(listId: newValue.id)
                }
            }
    }
    
    var formView: some View {
        NavigationStack{
            Form {
                Section {
                    TextField("Name", text: $name, axis: .vertical)
                    
                    TextField("Link", text: $link, axis: .vertical)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Notes", text: $note,  axis: .vertical)
                        .lineLimit(3...)
                }
                
                Section {
                    Picker(selection: $selectedList) {
                        ForEach(lists, id: \.id) { list in
                            Text("\(list.icon) \(list.name)")
                                .tag(list)
                        }
                    } label: {
                        HStack {
                            if loadingLists {
                                ProgressView()
                            }
                            
                            Text("List")
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker(selection: $selectedCategory) {
                        Text("No category").tag(nil as IxListCategory?)
                        
                        ForEach(categories, id: \.id) { category in
                            Text(category.name).tag(category as IxListCategory?)
                        }
                    } label: {
                        HStack {
                            if loadingCategories {
                                ProgressView()
                            }
                            
                            Text("Category")
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Save to list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        close()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let link = link.isEmpty ? nil : link
                            let note = note.isEmpty ? nil : note
                            
                            await save(
                                listId: selectedList.id,
                                categoryId: selectedCategory?.id,
                                name: name,
                                link: link,
                                note: note
                            )
                        }
                    }.disabled(name.isEmpty)
                }
            }
        }
    }

    func close() {
        NotificationCenter.default.post(name: NSNotification.Name("close.share.extension"), object: nil)
    }
}

#Preview {
    ShareExtensionView(name: "Think big!", link: nil)
}
