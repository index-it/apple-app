//
//  UIPlayground.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 27/12/25.
//

import SwiftUI

struct UIPlayground: View {
    var body: some View {
        NavigationView {
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                    Button {
                        
                    } label: {
                        Label("Create item", systemImage: "plus.circle.fill")
                            .labelStyle(.titleAndIcon)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                    }
            }
            
            
            
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.flexible, placement: .bottomBar)
            }
            
            ToolbarItem(placement: .bottomBar) {
                Menu {
                    Button("Cancel", role: .cancel) {}
                    
                    Button("Delete", systemImage: "trash", role: .destructive) {
                    }
                } label: {
                    Label("Delete category", systemImage: "trash")
                        .labelStyle(.titleOnly)
                }
            }

            

        }
    }
}

#Preview {
    UIPlayground()
}
