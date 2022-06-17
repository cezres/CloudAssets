//
//  CreateResourceState.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/8.
//

import Foundation
import ComposableArchitecture
import Combine
import CloudResourcesFoundation

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
        
        return Effect.run { subscriber in
            Task {
                let result: Result<Resource, Error>
                do {
//                    let record = try await env.cktool.createAssetsRecord(name: name, version: version, asset: url)
                    let data = try Data(contentsOf: url)
                    let record = try await env.cktool.createAssetsRecord(recordName: UUID().uuidString, name: name, version: version, pathExtension: url.pathExtension, asset: data)
                    let resource = Resource(
                        id: record.recordName,
                        name: record.name,
                        version: record.version,
                        pathExtension: record.pathExtension,
                        checksum: record.asset.fileChecksum
                    )
                    try resource.save(to: Database.default.database()!)
                    
                    if let data = try? Data(contentsOf: url) {
                        let asset = Asset(id: record.recordName, data: data)
                        try asset.save(to: Database.default.database()!)
                    }
                    result = .success(resource)
                } catch {
                    result = .failure(error)
                }
                DispatchQueue.main.async {
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
        state.isLoading = false
    case .setActive(let value):
        state.isActive = value
    case .setURL(let value):
        state.url = value
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
