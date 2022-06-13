//
//  CreateAssetState.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/8.
//

import Foundation
import ComposableArchitecture
import Combine

struct CreateAssetState: Equatable {
    var url: URL?
    var name: String = ""
    var version: String = ""
    var isActive: Bool = false
    var isUploading = false
}

enum CreateAssetAction {
    case confirm
    case completionHandler(Result<Resource, Error>)
    
    case update(Result<StateUpdater<CreateAssetState>, Error>)
    
    case setActive(Bool)
    case setURL(URL?)
    case setName(String)
    case setVersion(String)
    case setUploading(Bool)
}

let createAssetReducer = Reducer<CreateAssetState, CreateAssetAction, AppEnvironment>.init { state, action, env in
    switch action {
    case .confirm:
        guard
            let url = state.url,
            let version = Version.stringToInt(state.version),
            !state.name.isEmpty
        else {
            return .none
        }
        let name = state.name
        state.isUploading = true
        return Effect.task {
            let record = try await env.cktool.createAssetsRecord(name: name, version: version, asset: url)
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
            
            return resource
        }
        .receive(on: env.mainQueue)
        .catchToEffect(CreateAssetAction.completionHandler)
    case .completionHandler(let result):
        switch result {
        case .success(let value):
            state.version = ""
            state.name = ""
            state.url = nil
            state.isActive = false
        case .failure(let error):
            print(error)
            break
        }
        state.isUploading = false
    case .setActive(let value):
        state.isActive = value
    case .setURL(let value):
        state.url = value
    case .setName(let value):
        state.name = value
    case .setVersion(let value):
        state.version = value
    case .setUploading(let value):
        state.isUploading = value
    case .update(let result):
        switch result {
        case .success(let updater):
            updater(&state)
        case .failure(let error):
            debugPrint(error)
        }
    }
    return .none
}
