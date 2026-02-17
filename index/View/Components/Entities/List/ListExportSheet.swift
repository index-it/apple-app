//
//  ListExportSheet.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 14/02/26.
//

import SwiftUI
import IxCoreKit



struct ListExportSheet: View {
    var list: IxList
    var categories: [IxListCategory]
    var onExport: (ListExportConfig) -> Void
    
    @State private var format: ListExportFormat = .pdf
    @State private var filterByCategory = false
    @State private var categoryIdFilter: String? = nil
    @State private var includeCompletedItems = false
    @State private var includeItemLinks = true
    @State private var includeItemNotes = true
    @State private var itemNotesMaxLines = 3
    
    var body: some View {
        NavigationView {
            Form {
                Picker("Export Format", selection: $format) {
                    ForEach(ListExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(.init())
                .listRowBackground(Color.clear)
                
                Section {
                    Toggle(isOn: $includeCompletedItems) {
                        Text("Include completed items")
                    }
                    
                    Toggle(isOn: $filterByCategory) {
                        Text("Filter items by category")
                    }
                    
                    if filterByCategory {
                        Picker("Category", selection: $categoryIdFilter) {
                            Text("Uncategorized").tag(nil as String?)
                            
                            ForEach(categories, id: \.id) { category in
                                Text(category.name).tag(category.id)
                            }
                        }
                    }
                } header: {
                    Text("Filtering")
                }
                
                Section {
                    Toggle(isOn: $includeItemLinks) {
                        Text("Include item links")
                    }
                    
                    Toggle(isOn: $includeItemNotes) {
                        Text("Include item notes")
                    }
                    
                    if includeItemNotes {
                        Stepper("Max \(itemNotesMaxLines) note lines", value: $itemNotesMaxLines, in: 1...100)
                    }
                } header: {
                    Text("Appereance")
                }
            }
            .navigationTitle("Export list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onExport(
                            ListExportConfig(
                                format: format,
                                filterByCategory: filterByCategory,
                                categoryIdFilter: categoryIdFilter,
                                includeCompletedItems: includeCompletedItems,
                                includeItemLinks: includeItemLinks,
                                includeItemNotes: includeItemNotes,
                                itemNotesMaxLines: itemNotesMaxLines
                            )
                        )
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true
    
    VStack{}
        .sheet(isPresented: $isPresented) {
            ListExportSheet(
                list: .mock(name: "List", emoji: "🎲", color: "#FF00FF"),
                categories: [.mock(name: "Category")]
            ) { _ in }
        }
        .presentationDetents([.medium, .large])
}
