//
//  ListsHomePage.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import SwiftUI
import SwiftData
import MCEmojiPicker

struct ListsTabView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    @EnvironmentObject private var ixApiClient: IxApiClient
    @EnvironmentObject private var errorService: ErrorStateService
    @Environment(\.modelContext) private var context

    @Query var lists: [IxList]
    
    @State private var showCreationSheet = false
    @State private var newListNamePlaceholder: String? = nil
    @State private var newListColor: Color? = nil
    
    @State private var selectedList: IxList? = nil
    @State private var selectedListUsersWithAccess: [IxListSingleUserAccessInfo] = []
    @State private var showShareSheet = false
    @State private var showEditSheet = false
    @State private var showDeleteConfirmationDialog = false
    
    func fetchListTemplateSuggestion() async {
        do {
            let template = try await ixApiClient.getListTemplateSuggestion()
            
            newListNamePlaceholder = template.name
            newListColor = Color(hexString: template.color)
        } catch {
            
        }
    }
    
    func fetchLists() async {
        do {
            let lists = try await ixApiClient.getLists()
            
            try context.transaction {
                try context.delete(model: IxList.self)
                
                lists.forEach { ixList in
                    context.insert(ixList)
                }
                
                try context.save()
            }
        } catch {
            print(error)
            errorService.insert(.customMessage(message: "Something went wrong while trying to get your lists!"))
        }
    }
    
    func createList(name: String, color: Color, emoji: String, isPublic: Bool) async {
        do {
            let list = try await ixApiClient.createList(name: name, icon: emoji, color: color.hexString(), is_public: isPublic)
            
            context.insert(list)
        } catch IxApiClientError.InvalidData {
            errorService.insert(.customMessage(message: "Some list properties are not valid, please make sure to provide a valid name and emoji."))
        } catch IxApiClientError.ProRequired(let proFeature) {
            let message = if (proFeature == .public_list) {
                "You need Pro in order to create a public list."
            } else {
                "You need Pro to be able to create more than 10 lists."
            }
            
            let error = ErrorAlert.customMessage(
                title: "Pro required",
                message: message,
                buttons: [
                    ErrorAlert.Button(
                        title: "Get Pro",
                        isDestructive: false
                    ) {
                        // TODO
                        // navigationManager.push(navigationRoute: .GetPro)
                    }
                ]
            )
            
            errorService.insert(error)
        } catch {
            errorService.insert(.customMessage())
        }
    }
    
    func editList(id: String, name: String, color: Color, emoji: String, isPublic: Bool) async {
        do {
            let list = try await ixApiClient.editList(id: id, name: name, icon: emoji, color: color.hexString(), is_public: isPublic)
            
            try context.transaction {
                try context.delete(model: IxList.self, where: #Predicate { $0.id == id })
                context.insert(list)
                try context.save()
            }
        } catch {
        }
    }
    
    func fetchListUsersWthAccess(id: String) async {
        do {
            selectedListUsersWithAccess = try await ixApiClient.getListUsersWithAccess(id: id)
        } catch {
            // TODO
        }
    }
    
    func deleteList(id: String) async {
        do {
            try await ixApiClient.deleteList(id: id)
            try context.delete(model: IxList.self, where: #Predicate { $0.id == id })
        } catch IxApiClientError.NotFound {
            do { try context.delete(model: IxList.self, where: #Predicate { $0.id == id }) } catch {}
        } catch IxApiClientError.MissingPermission {
            // TODO
        } catch {
            errorService.insert(.customMessage())
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if lists.isEmpty {
                    EmptyView
                } else {
                    ListsGridView
                }
            }.navigationTitle("Your lists")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showCreationSheet = true
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                    }
                }
                .sheet(isPresented: $showShareSheet) {
                    // TODO: Loading indicator
                    ListSharingSheet(
                        showSheet: $showShareSheet,
                        isPublic: selectedList?.is_public ?? false,
                        usersWithAccess: $selectedListUsersWithAccess,
                        onPublicChange: { isPublic in
                            
                        }
                    ).presentationDetents([.large])
                }
                .sheet(isPresented: $showCreationSheet) {
                    ListFormSheet(
                        showSheet: $showCreationSheet,
                        name: "",
                        color: newListColor ?? Color.green,
                        emoji: String.randomEmoji(),
                        isPublic: false,
                        namePlaceholder: newListNamePlaceholder ?? "List name"
                    ) { name, color, emoji, isPublic in
                        Task {
                            await createList(name: name, color: color, emoji: emoji, isPublic: isPublic)
                        }
                    }
                        .presentationDetents([.large])
                }
                .sheet(isPresented: $showEditSheet) {
                    ListFormSheet(
                        showSheet: $showEditSheet,
                        name: selectedList?.name ?? "",
                        color: selectedList?.color.toColor(fallback: .green) ?? Color.green,
                        emoji: selectedList?.icon ?? String.randomEmoji(),
                        isPublic: selectedList?.is_public ?? false,
                        namePlaceholder: newListNamePlaceholder ?? "List name"
                    ) { name, color, emoji, isPublic in
                        if let selectedList {
                            Task {
                                await editList(id: selectedList.id, name: name, color: color, emoji: emoji, isPublic: isPublic)
                            }
                        }
                    }.presentationDetents([.large])
                }
                .confirmationDialog(
                    Text("Confirm deletion"),
                    isPresented: $showDeleteConfirmationDialog,
                    titleVisibility: .visible,
                    actions: {
                        Button("Delete", role: .destructive) {
                            if let selectedList {
                                Task {
                                    await deleteList(id: selectedList.id)
                                }
                            }
                        }
                        
                        Button("Keep", role: .cancel) {
                            showDeleteConfirmationDialog = false
                        }
                    },
                    message: {
                        Text("Are you sure you want to delete the list \(selectedList?.name ?? "")? This action is irreversible!")
                    }
                )
        }.onAppear {
            Task {
                let shouldSync = SyncRegister.shared.getCheckAndUpdate(SyncRegister.ResourceNames.LISTS)
                
                if (shouldSync) {
                    await fetchLists()
                }
            }
            
            Task {
                await fetchListTemplateSuggestion()
            }
        }.onChange(of: showCreationSheet, initial: true) {
            if showCreationSheet {
                Task {
                    await fetchListTemplateSuggestion()
                }
            }
        }
    }
    
    private var EmptyView: some View {
        VStack {
            Spacer()
            
            ContentUnavailableView {
                Label("No lists", systemImage: "binoculars")
            } description: {
                Text("You don't have any list yet!")
            } actions: {
                Button {
                    showCreationSheet = true
                } label: {
                    Label("Create a list", systemImage: "plus")
                }.buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }.frame(maxHeight: .infinity)
    }
    
    private var ListsGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(lists.sorted(by: { first, second in
                    first.name < second.name
                })) { list in
                    ListCard(
                        list: list,
                        onTap: {
                            
                        },
                        onShare: {
                            selectedList = list
                            Task {
                                await fetchListUsersWthAccess(id: list.id)
                            }
                            showShareSheet = true
                        },
                        onEdit: {
                            selectedList = list
                            showEditSheet = true
                        },
                        onDelete: {
                            selectedList = list
                            showDeleteConfirmationDialog = true
                        }
                    )
                }
            }.padding()
        }
    }
}

#Preview {
    @Previewable @StateObject var ixApiClient = IxApiClient()
    @Previewable @StateObject var errorService = ErrorStateService()
    
    ListsTabView()
        .environmentObject(ixApiClient)
        .environmentObject(errorService)
}
