//
//  ResourceIndexesView.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/9.
//

import SwiftUI
import ComposableArchitecture
import SwiftUIX

struct ResourceIndexesView: View {
    let store: Store<ResourceIndexState, ResourceIndexAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            HStack {
                Button {
                    viewStore.send(.upload)
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Upload")
                    }
                }
                
                Button {
                    viewStore.send(.download)
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Download")
                    }
                }
                Button {
                    viewStore.send(.delete)
                } label: {
                    HStack {
                        Image(systemName: "delete.forward")
                        Text("Delete")
                    }
                }
                
                Spacer()
            }
            .buttonStyle(.borderedProminent)
            .padding(Edge.Set.init(arrayLiteral: .horizontal, .top), 16)
            
            GeometryReader { proxy in
                HStack {
                    resourcesListView(viewStore.leftList, viewStore: viewStore, tapAction: ResourceIndexAction.tapLeft)
                    .frame(width: proxy.size.width / 2)
                    Divider()
                    resourcesListView(viewStore.rightList, viewStore: viewStore, tapAction: ResourceIndexAction.tapRight)
                }
            }
            .padding(Edge.Set.vertical, 16)
            .loading(viewStore.binding(get: \.isLoading, send: ResourceIndexAction.setLoading))
            .error(viewStore.binding(get: \.error, send: ResourceIndexAction.setError))
        }
    }
    
    func resourcesListView(_ resources: [Resource], viewStore: ViewStore<ResourceIndexState, ResourceIndexAction>, tapAction: @escaping (Resource) -> ResourceIndexAction) -> some View {
        let rightData = viewDataOfAssets(resources)
        return ScrollView {
            ForEach.init(rightData) { element in
                HStack(spacing: 12) {
                    ForEach.init(element.assets) { resource in
                        ResourceView(resource: resource) { resource in
                        }
                        .onTapGesture {
                            viewStore.send(tapAction(resource))
                        }
                    }
                    Spacer()
                }
            }
        }
    }
    
    struct AssetsRow: Identifiable {
        let id: Int
        let assets: [Resource]
        
        init(assets: [Resource]) {
            self.assets = assets
            
            var hasher = Hasher()
            assets.forEach { element in
                hasher.combine(element.id)
            }
            id = hasher.finalize()
        }
    }
    
    func viewDataOfAssets(_ assets: [Resource]) -> [AssetsRow] {
        var datas: [[Resource]] = []
        for asset in assets {
            if let list = datas.last, list.count < 3 {
                datas[datas.count - 1].append(asset)
            } else {
                datas.append([asset])
            }
        }
        return datas.map { AssetsRow(assets: $0) }
    }
}
