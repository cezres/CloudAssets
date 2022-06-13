//
//  CreateResourceIndexesView.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/9.
//

import SwiftUI
import SwiftUIX
import ComposableArchitecture
import CloudResourcesFoundation

struct CreateResourceIndexesView: View {
    let store: Store<CreateResourceIndexState, CreateResourceIndexAction>
    let indexes: [ResourceIndexes]
    
    var body: some View {
        WithViewStore(store) { viewStore in
            Form {
                Section {
                    Text("Create Resource Indexes")
                        .font(Font.title)
                    
                    TextField("Version", text: viewStore.binding(get: \.version, send: CreateResourceIndexAction.setVersion))
                    
                    if !indexes.isEmpty {
                        Picker(selection: Binding<Int?>.init {
                            viewStore.base?.version
                        } set: { newValue in
                            viewStore.send(.setBase(indexes.first(where: { $0.version == newValue })))
                        }) {
                            ForEach(indexes) { element in
                                Text(Version.intVersionToString(element.version)).tag(element.version)
                            }
                        } label: {
                            Text("Base")
                        }
                    }
                }
                
                Spacer(minLength: 30)
                
                Section {
                    HStack(spacing: 24) {
                        Button {
                            viewStore.send(.confirm)
                        } label: {
                            Text("Confirm")
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.blue)
                        }
                        .buttonStyle(.borderless)
                        .cornerRadius(8)
                        .padding(.bottom, 30)
                        
                        Button {
                            viewStore.send(.setActive(false))
                        } label: {
                            Text("Cancel")
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.blue)
                        }
                        .buttonStyle(.borderless)
                        .cornerRadius(8)
                        .padding(.bottom, 30)
                    }
                }
            }
            .padding(30)
            .frame(minWidth: 600, minHeight: 300)
            .loading(viewStore.binding(get: \.isLoading, send: CreateResourceIndexAction.setLoading))
        }
    }
}

