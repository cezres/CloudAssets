//
//  DeployView.swift
//  CloudResourcesManager
//
//  Created by azusa on 2022/6/13.
//

import SwiftUI
import ComposableArchitecture

struct DeployView: View {
    let store: Store<DeployState, DeployAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .center) {
                Text("Changes")
                    .font(.title)
                    .padding(16)
                ScrollView {
                    if !viewStore.newIndexes.isEmpty {
                        Text("New Indexes")
                            .font(.title2)
                        ForEach(viewStore.newIndexes) { element in
                            Text(Version.intVersionToString(element.version))
                                .foregroundColor(.systemGreen)
                        }
                    }
                    if !viewStore.deleteIndexes.isEmpty {
                        Text("Delete Indexes")
                            .font(.title2)
                        ForEach(viewStore.deleteIndexes) { element in
                            Text(Version.intVersionToString(element.version))
                                .foregroundColor(.systemRed)
                        }
                    }
                    if !viewStore.updateIndexes.isEmpty {
                        Text("Update Indexes")
                            .font(.title2)
                        ForEach(viewStore.updateIndexes) { element in
                            Text(Version.intVersionToString(element.version))
                                .foregroundColor(.systemOrange)
                        }
                    }
                    
                    if !viewStore.newResources.isEmpty {
                        Text("New Resources")
                            .font(.title2)
                        ForEach(viewStore.newResources) { element in
                            Text(element.name + " (\(Version.intVersionToString(element.version)))")
                                .foregroundColor(.systemGreen)
                        }
                    }
                }

                if viewStore.isDeploying {
                    HStack {
                        Button {
                            viewStore.send(.deploy)
                        } label: {
                            Text("Deploy")
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.blue)
                        }
                        .buttonStyle(.borderless)
                        .cornerRadius(8)
                        
                        Button {
                            viewStore.send(.cancel)
                        } label: {
                            Text("Cancel")
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.blue)
                        }
                        .buttonStyle(.borderless)
                        .cornerRadius(8)
                    }
                } else {
                    Button {
                        viewStore.send(.loadChanges)
                    } label: {
                        Text("Deploy Resources And Indexes Changes")
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.blue)
                    }
                    .buttonStyle(.borderless)
                    .cornerRadius(8)
                }
                
            }
            .loading(viewStore.binding(get: \.isLoading, send: DeployAction.setLoading))
            .error(viewStore.binding(get: \.error, send: DeployAction.setError))
            .padding(30)
        }
        
    }
}

