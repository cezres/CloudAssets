//
//  ResourcesState.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/6.
//

import Foundation
import ComposableArchitecture

struct ResourcesState: Equatable {
    var resources: [Resource] = []
    var loading: Bool = false
}

enum ResourcesAction {
    case deleteAsset(Resource)
    case deleteAssetResponse(Result<Resource, Error>)
    
    case setLoading(Bool)
}

let assetsReducer = Reducer<ResourcesState, ResourcesAction, AppEnvironment>.init { state, action, env in
    switch action {
    case .deleteAsset(let asset):
        state.loading = true
        return Effect.task {
            try await env.cktool.deleteRecord(recordName: asset.id)
            try asset.delete(to: Database.default.database()!)
            return asset
        }
        .receive(on: env.mainQueue)
        .catchToEffect(ResourcesAction.deleteAssetResponse)
        
    case .deleteAssetResponse(let result):
        switch result {
        case .success(let asset):
            if let index = state.resources.firstIndex(where: { $0.id == asset.id }) {
                state.resources.remove(at: index)
            }
        case .failure(let error):
            debugPrint(error)
        }
        state.loading = false
        
    case .setLoading(let value):
        state.loading = value
    }
    return .none
}
