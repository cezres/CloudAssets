//
//  CreateAssetView.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/8.
//

import SwiftUI
import ComposableArchitecture
import SwiftUIX

struct CreateAssetView: View {
    let store: Store<CreateAssetState, CreateAssetAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            Form {
                Section {
                    Text("Upload Asset")
                        .font(Font.title)
                    
                    if let url = viewStore.url {
                        Text(url.path)
                            .padding(.top, 30)
                    }
                    Button {
                        let panel = NSOpenPanel()
                        panel.title = "Open a file"
                        panel.canChooseFiles = true
                        panel.canChooseDirectories = false
                        guard panel.runModal() == .OK else {
                            return
                        }
                        guard let url = panel.url else {
                            return
                        }
                        viewStore.send(.setURL(url))
                    } label: {
                        Text("Choose File")
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.blue)
                    }
                    .buttonStyle(.borderless)
                    .cornerRadius(8)
                    .padding(.bottom, 30)
                    
                    TextField("Name", text: viewStore.binding(get: \.name, send: CreateAssetAction.setName))
                    
                    TextField("Version", text: viewStore.binding(get: \.version, send: CreateAssetAction.setVersion))
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
            .sheet(isPresented: viewStore.binding(get: \.isUploading, send: CreateAssetAction.setUploading)) {
                VStack {
                    ActivityIndicator()
                }
                .frame(width: 100, height: 100, alignment: .center)
                .cornerRadius(12)
            }
        }
    }
}

