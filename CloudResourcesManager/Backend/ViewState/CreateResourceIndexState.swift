//
//  CreateResourceIndexState.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/9.
//

import Foundation
import ComposableArchitecture
import Combine
import CloudResourcesFoundation

struct CreateResourceIndexState: Equatable {
    var isActive: Bool = false
    var version: String = ""
    var base: ResourceIndexes?
    var isLoading: Bool = false
}

enum CreateResourceIndexAction {
    case setActive(Bool)
    case setLoading(Bool)
    case setVersion(String)
    case setBase(ResourceIndexes?)
    case confirm
    case completion(ResourceIndexes)
}

let createResourceIndexReducer = Reducer<CreateResourceIndexState, CreateResourceIndexAction, AppEnvironment>.init { state, action, env in
    switch action {
    case .confirm:
        guard let version = Version.stringVersionToInt(state.version) else {
            break
        }
        let indexes = state.base?.indexes ?? [:]
        let resourceIndex = ResourceIndexes(id: "\(version)_resource_index", version: version, indexes: indexes, checksum: "")
        
        return Effect.run { subscriber in
            subscriber.send(.setLoading(true))
            Task {
                do {
                    let record = try await env.cktool.createResourceIndexRecord(indexes: resourceIndex)
                    
                    let resourceIndex = ResourceIndexes(id: record.recordName, version: record.version, indexes: indexes, checksum: record.indexes.fileChecksum)
                    try env.database.save(resourceIndex)
                    
                    DispatchQueue.main.async {
                        subscriber.send(.setLoading(false))
                        subscriber.send(.setActive(false))
                        subscriber.send(.completion(resourceIndex))
                    }
                } catch {
                    DispatchQueue.main.async {
                        subscriber.send(.setLoading(false))
                    }
                }
            }
            return AnyCancellable {}
        }
    case .completion(let result):
        break
    case .setActive(let value):
        state.isActive = value
    case .setVersion(let value):
        state.version = value
    case .setBase(let value):
        state.base = value
    case .setLoading(let value):
        state.isLoading = value
    }
    return .none
}
