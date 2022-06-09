//
//  CreateResourceIndexState.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/9.
//

import Foundation
import ComposableArchitecture

struct CreateResourceIndexState: Equatable {
    var isActive: Bool = false
    var version: String = ""
    var base: ResourceIndex?
}

enum CreateResourceIndexAction {
    case setActive(Bool)
    case setVersion(String)
    case setBase(ResourceIndex?)
    case confirm
    case completion(Result<ResourceIndex, Error>)
}

let createResourceIndexReducer = Reducer<CreateResourceIndexState, CreateResourceIndexAction, AppEnvironment>.init { state, action, env in
    switch action {
    case .confirm:
        guard let version = Version.stringToInt(state.version) else {
            break
        }
        let indexes = state.base?.indexes ?? [:]
        return Effect<ResourceIndex, Error>.result {
            let resourceIndex = ResourceIndex(id: "\(version)_resource_index", version: version, indexes: indexes, checksum: "")
            do {
                try env.database.save(resourceIndex)
                return .success(resourceIndex)
            } catch {
                return .failure(error)
            }
        }
        .receive(on: env.mainQueue)
        .catchToEffect(CreateResourceIndexAction.completion)
    case .completion(let result):
        switch result {
        case .success:
            state.isActive = false
        case .failure(let error):
            print(error)
        }
    case .setActive(let value):
        state.isActive = value
    case .setVersion(let value):
        state.version = value
    case .setBase(let value):
        state.base = value
    }
    return .none
}
