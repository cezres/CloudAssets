//
//  ResourcesState.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/6.
//

import Foundation
import ComposableArchitecture
import Combine

struct ResourcesState: Equatable {
    var resources: [Resource] = []
    var loading: Bool = false
    var error: String = ""
}

enum ResourcesAction {
    case deleteAsset(Resource)
    case deleteAssetResponse(Result<Resource, Error>)
    
    case setLoading(Bool)
    case setError(String)
    
    case resourceItem(ResourceItemState.ID, ResourceItemAction)
}

let resourcesReducer = Reducer<ResourcesState, ResourcesAction, AppEnvironment>.init { state, action, env in
    switch action {
    case .deleteAsset(let asset):
        state.loading = true
        return Effect.run { subscriber in
//            Task {
//                let result: Result<Resource, Error>
//                do {
//                    try await env.cktool.deleteRecord(recordName: asset.id)
//                    try asset.delete(to: Database.default.database()!)
//                    result = .success(asset)
//                } catch {
//                    result = .failure(error)
//                }
//                DispatchQueue.main.async {
//                    subscriber.send(.deleteAssetResponse(result))
//                }
//            }
            return AnyCancellable {}
        }
        
    case .deleteAssetResponse(let result):
        switch result {
        case .success(let asset):
            if let index = state.resources.firstIndex(where: { $0.id == asset.id }) {
                state.resources.remove(at: index)
            }
        case .failure(let error):
            state.error = error.toString()
        }
        state.loading = false
        
    case .setLoading(let value):
        state.loading = value
    case .setError(let error):
        state.error = error
        
    case .resourceItem(let id, let action):
        break
    }
    return .none
}
