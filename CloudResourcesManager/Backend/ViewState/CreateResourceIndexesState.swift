//
//  CreateResourceIndexesState.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/9.
//

import Foundation
import ComposableArchitecture
import Combine

struct CreateResourceIndexesState: Equatable {
    var isActive: Bool = false
    var version: String = ""
    var base: ResourceIndexesRecord?
    var isLoading: Bool = false
    var error: String = ""
}

enum CreateResourceIndexesAction {
    case setActive(Bool)
    case setLoading(Bool)
    case setError(String)
    case setVersion(String)
    case setBase(ResourceIndexesRecord?)
    case confirm
    case completion(ResourceIndexesRecord)
}

let createResourceIndexesReducer = Reducer<CreateResourceIndexesState, CreateResourceIndexesAction, AppEnvironment>.init { state, action, env in
    switch action {
    case .confirm:
        guard let version = Version.stringVersionToInt(state.version) else {
            break
        }
        let indexes = state.base?.indexes ?? [:]
        let resourceIndex = ResourceIndexesRecord(recordName: "\(version)_resource_index", modifiedTimestamp: 0, version: version, indexes: indexes)
        
        return Effect.run { subscriber in
            subscriber.send(.setLoading(true))
//            Task {
//                do {
//                    let record = try await env.cktool.createResourceIndexRecord(indexes: resourceIndex)
//                    
//                    let resourceIndex = ResourceIndexesRecord(recordName: record.recordName, version: record.version, indexes: indexes, checksum: record.indexes.fileChecksum)
////                    ResourceIndexesRecord(recordName: <#T##String#>, modifiedTimestamp: <#T##Double#>, version: <#T##Int#>, indexes: <#T##ResourceIndexes#>)
//                    try env.database.save(resourceIndex)
//                    
//                    DispatchQueue.main.async {
//                        subscriber.send(.setLoading(false))
//                        subscriber.send(.setActive(false))
//                        subscriber.send(.completion(resourceIndex))
//                    }
//                } catch {
//                    DispatchQueue.main.async {
//                        subscriber.send(.setLoading(false))
//                        subscriber.send(.setError(error.toString()))
//                    }
//                }
//            }
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
    case .setError(let value):
        state.error = value
    }
    return .none
}
