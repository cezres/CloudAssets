//
//  ResourceIndexView.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/9.
//

import SwiftUI
import ComposableArchitecture

struct ResourceIndexView: View {
    let store: Store<ResourceIndexState, ResourceIndexAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            GeometryReader { proxy in
                HStack {
                    resourcesListView(viewStore.leftList, viewStore: viewStore, tapAction: ResourceIndexAction.tapLeft)
                    .frame(width: proxy.size.width / 2)
                    Divider()
                    resourcesListView(viewStore.rightList, viewStore: viewStore, tapAction: ResourceIndexAction.tapRight)
                }
            }
            .padding(Edge.Set.vertical, 16)
            .toolbar {
                ToolbarItem {
                    Button {
                        print("xx")
//                        viewStore.send(.createResourceIndex(.setActive(true)))
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text("Add Indexes")
                        }
                    }
                }
                ToolbarItem {
                    Button {
                        print("xx")
//                        viewStore.send(.loadFromCloud)
                    } label: {
                        HStack {
                            Image(systemName: "goforward")
                            Text("Refresh")
                        }
                        
                    }
                }
            }
        }
    }
    
    func resourcesListView(_ resources: [Resource], viewStore: ViewStore<ResourceIndexState, ResourceIndexAction>, tapAction: @escaping (Resource) -> ResourceIndexAction) -> some View {
        let rightData = viewDataOfAssets(resources)
        return ScrollView {
            ForEach.init(rightData) { element in
                HStack(spacing: 12) {
                    ForEach.init(element.assets) { resource in
                        AssetView(resource: resource) { resource in
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
