//
//  ContentView.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/2.
//

import SwiftUI
import WebKit
import ComposableArchitecture
import CloudResourcesFoundation

struct ContentView: View {
    
    let store: Store<AppState, AppAction>
    
    var body: some View {
        ZStack {
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
                                DeployView()
                            } label: {
                                Text("Deploy")
                            }
                        }
                        header: {
                            Text(viewStore.configuration.environment.rawValue)
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

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}

struct __WebView: NSViewRepresentable {
    let cktool: CKToolJS
    
    func makeNSView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .init(x: 0, y: 0, width: 200, height: 200), configuration: .init())
//        view.navigationDelegate = context.coordinator
        cktool.webView = view
        view.navigationDelegate = cktool
        view.configuration.userContentController.add(cktool, name: "bridge")
        return view
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString("""
        <!DOCTYPE html>
        <html>
        <body>
        <script>
        document.write("<h1>这是一个标题</h1>");
        document.write("<p>这是一个段落</p>");
        </script>
        </body>
        </html>
        """, baseURL: nil)
        cktool.webView = nsView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(javaScriptString: cktool.javaScriptString)
    }
    
    typealias NSViewType = WKWebView
    
    class Coordinator: NSObject,WKNavigationDelegate {
        let javaScriptString: String
        
        init(javaScriptString: String) {
            self.javaScriptString = javaScriptString
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        }
    }
}
