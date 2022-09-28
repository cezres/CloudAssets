//
//  CreateResourceState.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/8.
//

import Foundation
import ComposableArchitecture
import Combine

struct CreateResourceState: Equatable {
    var url: URL?
    var name: String = ""
    var version: String = ""
    var isActive: Bool = false
    var isLoading = false
    var error: String = ""
}

enum CreateResourceAction {
    case confirm
    case completionHandler(Result<Resource, Error>)
    
    case update(Result<StateUpdater<CreateResourceState>, Error>)
    
    case setActive(Bool)
    case setURL(URL?)
    case setName(String)
    case setVersion(String)
    case setLoading(Bool)
    case setError(String)
}

let createResourceReducer = Reducer<CreateResourceState, CreateResourceAction, AppEnvironment>.init { state, action, env in
    switch action {
    case .confirm:
        guard
            let url = state.url,
            let version = Version.stringVersionToInt(state.version),
            !state.name.isEmpty
        else {
            return .none
        }
        let name = state.name
        state.isLoading = true
        let record = Resource.init(id: UUID().uuidString, name: state.name, version: version, pathExtension: url.pathExtension, fileChecksum: "", modifiedTimestamp: Date().timeIntervalSince1970)
        return Effect.run { subscriber in
            Task.detached {
                let result: Result<Resource, Error>
                do {
                    let data = try Data(contentsOf: url)
                    let asset = Asset(id: record.id, data: data)
                    try env.localDatabase.insert(asset)
                    try env.localDatabase.insert(record)
                    // 添加同步数据到iCloud的后台任务
                    result = .success(record)
                } catch {
                    result = .failure(error)
                }
                await MainActor.run {
                    subscriber.send(.setLoading(false))
                    subscriber.send(.completionHandler(result))
                }
            }
            return AnyCancellable {}
        }
    case .completionHandler(let result):
        switch result {
        case .success(let value):
            state.version = ""
            state.name = ""
            state.url = nil
            state.isActive = false
        case .failure(let error):
            state.error = error.toString()
        }
//        state.isLoading = false
    case .setActive(let value):
        state.isActive = value
    case .setURL(let value):
        state.url = value
        state.name = value?.lastPathComponent ?? ""
    case .setName(let value):
        state.name = value
    case .setVersion(let value):
        state.version = value
    case .setLoading(let value):
        state.isLoading = value
    case .setError(let value):
        state.error = value
    case .update(let result):
        switch result {
        case .success(let updater):
            updater(&state)
        case .failure(let error):
            state.error = error.toString()
        }
    }
    return .none
}
