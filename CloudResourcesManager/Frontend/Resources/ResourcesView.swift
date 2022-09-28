//
//  ResourcesView.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/4.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import SwiftUIX

struct ResourcesView: View {
    let store: Store<ResourcesState, ResourcesAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            let data = viewDataOfAssets(viewStore.resources)
            ScrollView {
                Text("")
                    .frame(height: 16)
                
                
//                let store = store.scope(state: { state in
////                    state.resources.map { ResourceItemState(resource: $0) }
//                    state.resources
//                }, action: ResourcesAction.resourceItem)
                
//                ForEachStore(store.scope(state: \.resources, action: \ResourcesAction.resourceItem), id: \Resource.id) { store in
//                    
//                }
                
//                ForEachStore(store) { store in
//                    ResourceItemView(store: store) { resource in
//                        viewStore.send(.deleteAsset(resource))
//                    }
//                }
                
//                WithViewStore(store.scope(state: { state in
//                    state.resources.map { ResourceItemState(resource: $0) }
//                }, action: <#T##(LocalAction) -> Action#>), content: <#T##(ViewStore<State, Action>) -> Content#>)
                
//                ForEachStore(store, id: \.resources, content: <#T##(Store<EachState, EachAction>) -> EachContent#>)
                
//                ForEach.init(data) { element in
//                    HStack(spacing: 12) {
//                        ForEach.init(element.assets) { resource in
//                            ResourceItemView(resource: resource) { resource in
//                                viewStore.send(.deleteAsset(resource))
//                            }
//                        }
//                        Spacer()
//                    }
//                }
            }
            .loading(viewStore.binding(get: \.loading, send: ResourcesAction.setLoading))
            .error(viewStore.binding(get: \.error, send: ResourcesAction.setError))
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
            if let list = datas.last, list.count < 6 {
                datas[datas.count - 1].append(asset)
            } else {
                datas.append([asset])
            }
        }
        return datas.map { AssetsRow(assets: $0) }
    }
}
