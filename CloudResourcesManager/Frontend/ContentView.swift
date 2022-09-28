//
//  ContentView.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/2.
//

import SwiftUI
import WebKit
import ComposableArchitecture

struct ContentView: View {
    
    let store: Store<AppState, AppAction>
    
    var newBody: some View {
        NavigationSplitView {
            //
        } detail: {
            //
        }
    }
    
    var body: some View {
        WithViewStore(store) { viewStore in
            NavigationView {
                List {
                    Section {
                        ForEachStore(store.scope(state: \.resourceIndexes, action: AppAction.resourceIndexes)) { store in
                            WithViewStore(store) { viewStore in
                                NavigationLink(
                                    isActive: viewStore.binding(get: \.isActive, send: ResourceIndexAction.setActive)
                                ) {
                                    ResourceIndexesView(store: store)
                                } label: {
                                    Text(Version.intVersionToString(viewStore.index.version))
                                }
                            }
                        }
                    } header: {
                        Text("Indexes")
                    }
                                            
                    Section {
                        NavigationLink("Resources") {
                            ResourcesView(store: store.scope(state: \.resources, action: AppAction.resources))
                        }
                    } header: {
                        Text("Resources")
                    }
                    
                    Section {
                        NavigationLink {
                            ConfigurationView(store: store.scope(state: \.configuration, action: AppAction.configuration))
                        } label: {
                            Text("Configuration")
                        }
                        
                        NavigationLink {
                            DeployView(store: store.scope(state: \.deploy, action: AppAction.deploy))
                        } label: {
                            Text("Deploy")
                        }
                    }
                    header: {
//                            Text(viewStore.configuration.environment.rawValue)
                        Text("Configuration")
                    }
                }
                .listStyle(SidebarListStyle())
                .frame(minWidth: 160)
            }
            .toolbar {
                toolbar(viewStore: viewStore)
            }
            .frame(minWidth: 1000, minHeight: 600)
            .onAppear {
                viewStore.send(.loadFromDB)
            }
            .sheet(isPresented: viewStore.binding(
                get: { $0.createResource.isActive },
                send: { AppAction.createResource(.setActive($0)) }
            )) {
                CreateResourceView(store: store.scope(state: \.createResource, action: AppAction.createResource))
            }
            .sheet(isPresented: viewStore.binding(
                get: { $0.createResourceIndexes.isActive },
                send: { AppAction.createResourceIndexes(.setActive($0)) }
            )) {
                CreateResourceIndexesView(
                    store: store.scope(state: \.createResourceIndexes, action: AppAction.createResourceIndexes),
                    indexes: viewStore.resourceIndexes.map { $0.index }
                )
            }
            .error(viewStore.binding(get: \.error, send: AppAction.setError))
        }
    }
    
    func toolbar(viewStore: ViewStore<AppState, AppAction>) -> some ToolbarContent {
        ToolbarContentBuilder.buildBlock(
            ToolbarItem {
                Button {
                    viewStore.send(.createResourceIndexes(.setActive(true)))
                } label: {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Add Indexes")
                    }
                }
            },
            ToolbarItem {
                Button {
                    viewStore.send(.createResource(.setActive(true)))
                } label: {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Add Resource")
                    }
                }
            },
            ToolbarItem {
                Button {
                    viewStore.send(.loadFromCloud)
                } label: {
                    HStack {
                        Image(systemName: "goforward")
                        Text("Refresh")
                    }
                    
                }
            }
        )
    }
}

enum Link: Hashable, Identifiable {
    case indexes(String)
    case resources
    case configuration
    case deploy
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .indexes(let value):
            hasher.combine(0)
            hasher.combine(value)
        case .resources:
            hasher.combine(1)
        case .configuration:
            hasher.combine(2)
        case .deploy:
            hasher.combine(3)
        }
    }
    
    var id: Int { hashValue }
}

fileprivate struct Sidebar: View {
    
    var selection: Binding<Link>
    var resourceIndexes: IdentifiedArrayOf<ResourceIndexState> = []
    
    var body: some View {
        List(selection: selection) {
            Section {
                ForEach(resourceIndexes) { value in
                    Text(Version.intVersionToString(value.index.version)).tag(Link.indexes(value.id))
                }
            } header: {
                Text("Indexes")
            }
            
            Section {
                Text("Resources").tag(Link.resources)
            }
            
            Section {
                Text("Configuration").tag(Link.configuration)
                Text("Deploy").tag(Link.deploy)
            }
        }
    }
}

fileprivate struct DetailView: View {
    
    var selection: Link
    
    let store: Store<AppState, AppAction>
    
    @State var path: NavigationPath = .init()
    
    var body: some View {
        switch selection {
        case .indexes:
            Text("xxxxx")
//            WithViewStore(store.scope(state: \.resourceIndexes, action: AppAction.resourceIndexes)) { viewStore in
//                viewStore
//            }
//            ResourceIndexesView(store: <#T##Store<ResourceIndexState, ResourceIndexAction>#>)
//            ResourcesIndexesView()
//                .toolbar {
//                    ToolbarItem {
//                        Button {
//                        } label: {
//                            HStack {
//                                Image(systemName: "doc.badge.plus")
//                                Text("Add Indexes")
//                            }
//                        }
//                    }
//                }
        case .resources:
//            ResourcesView()
            Text("xxx")
                .toolbar {
                    ToolbarItem {
                        Button {
                        } label: {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                Text("Add Resource")
                            }
                        }
                    }
                    ToolbarItem {
                        Button {
                        } label: {
                            HStack {
                                Image(systemName: "goforward")
                                Text("Refresh")
                            }

                        }
                    }
                }
        case .configuration:
//            ConfigurationView(configuration: state.configuration)
            Text("xxx")
        case .deploy:
//            DeployView()
            Text("xxx")
        }
    }
    
    func makeNavigationStack(root: some View) -> some View {
        NavigationStack {
            root
        }
        .toolbar {
            ToolbarItem {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text("Add Indexes")
                }
            }
        }
    }
}


//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
