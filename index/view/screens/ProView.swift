//
//  ProView.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 28/02/25.
//

import SwiftUI

struct ProView: View {
    private struct ProFeatureShowcase {
        let icon: String
        let title: String
    }
    
    static private var features: [ProFeatureShowcase] = [
        .init(icon: "infinity", title: "Unlimited lists"),
        .init(icon: "person.3.fill", title: "Public lists"),
        .init(icon: "bell.fill", title: "Unlimited task reminders"),
        .init(icon: "hammer.fill", title: "Support the development")
    ]
    
    @State private var yearly: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Text("be intentional.\nget pro.")
                    .multilineTextAlignment(.center)
                    .font(.title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                PlaceholderView()
                    .frame(maxHeight: 128)
                
                Spacer()
                
                VStack {
                    VStack(alignment: .leading) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading) {
                                Text("Monthly")
                                    .font(.headline)
                                Text("$1.99 per month")
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            Toggle(isOn: Binding(
                                get: { !yearly },
                                set: { yearly = !$0 }
                            )) {
                                Text("I'm not a robot")
                            }
                            .toggleStyle(iOSCheckboxToggleStyle())
                            .scaleEffect(1.2)
                        }.padding()
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(UIColor.tertiarySystemBackground.toColor())
                            .if(!yearly, transform: { view in
                                view
                                    .stroke(Color.accentColor, lineWidth: 2)
                            })
                           
                    }
                    .padding(.horizontal)
                    .onTapGesture {
                        yearly = false
                    }
                    
                    VStack(alignment: .leading) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading) {
                                Text("Yearly")
                                    .font(.headline)
                                Text("$19.99 per year")
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            Toggle(isOn: $yearly) {
                                Text("I'm not a robot")
                            }
                            .toggleStyle(iOSCheckboxToggleStyle())
                            .scaleEffect(1.2)
                        }.padding()
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(UIColor.tertiarySystemBackground.toColor())
                            .if(yearly, transform: { view in
                                view
                                    .stroke(Color.accentColor, lineWidth: 2)
                            })
                           
                    }
                    .padding(.horizontal)
                    .onTapGesture {
                        yearly = true
                    }
                    
                    Button {
                        
                    } label: {
                        Text("Upgrade")
                            .frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding()
                    
                    Button {
                        
                    } label: {
                        Text("Restore purchases")
                    }
                        
                }.frame(maxWidth: .infinity)
            }
            .meshGradientBackground()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            // TODO
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                            
                        }
                    }
                }
        }.environment(\.colorScheme, .dark)
    }
}

#Preview {
    ProView()
}
