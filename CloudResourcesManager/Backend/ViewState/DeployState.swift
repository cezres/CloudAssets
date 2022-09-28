//
//  DeployState.swift
//  CloudResourcesManager
//
//  Created by azusa on 2022/6/16.
//

import Foundation
import ComposableArchitecture
import Combine

struct DeployState: Equatable {
    var newIndexes: [ResourceIndexesRecord] = []
    var deleteIndexes: [ResourceIndexesRecord] = []
    var updateIndexes: [ResourceIndexesRecord] = []
    
    var newResources: [Resource] = []
    var deleteResources: [Resource] = []
    var updateResources: [Resource] = []
    
    var isDeploying = false
    var isLoading = false
    var error = ""
}

enum DeployAction {
    case loadChanges
    case deploy
    case cancel
    
    case setNewIndexes([ResourceIndexesRecord])
    case setDeleteIndexes([ResourceIndexesRecord])
    case setUpdateIndexes([ResourceIndexesRecord])
    
    case setNewResources([Resource])
    case setDeleteResources([Resource])
    case setUpdateResources([Resource])
    
    case setDeploying(Bool)
    case setLoading(Bool)
    case setError(String)
}

let deployReducer = Reducer<DeployState, DeployAction, AppEnvironment>.init { state, action, env in
    switch action {
    case .setNewIndexes(let value):
        state.newIndexes = value
    case .setDeleteIndexes(let value):
        state.deleteIndexes = value
    case .setUpdateIndexes(let value):
        state.updateIndexes = value
    case .setNewResources(let value):
        state.newResources = value
    case .setDeleteResources(let value):
        state.deleteResources = value
    case .setUpdateResources(let value):
        state.updateResources = value
    case .setLoading(let value):
        state.isLoading = value
    case .setError(let value):
        state.isLoading = false
        state.error = value
    case .setDeploying(let value):
        state.isLoading = false
        state.isDeploying = value
        
    case .loadChanges:
        state.isLoading = true
        return Effect.run { subscriber in
//            Task {
//                let configure = env.database.loadCKToolConfiguration()
//                DispatchQueue.main.sync {
//                    env.cktool.configureEnvironment(configure.containerId, environment: "PRODUCTION", ckAPIToken: configure.productionCKAPIToken, ckWebAuthToken: configure.productionCKWebAuthToken)
//                }
//                do {
//                    // Resource Indexes
//                    // load production data from cloud kit
//                    var cloudIndexes = try await env.productCloud.queryResourceIndexRecords()
//                    // load development data from local database
//                    let localIndexes: [ResourceIndexesRecord] = try env.database.query()
//                    var _newIndexes: [ResourceIndexes] = []
//                    var _updateIndexes: [ResourceIndexes] = []
//                    localIndexes.forEach { indexes in
//                        if let resultIndex = cloudIndexes.firstIndex(where: { $0.recordName == indexes.id }) {
//                            let result = cloudIndexes.remove(at: resultIndex)
//                            if indexes.checksum != result.indexes.fileChecksum {
//                                _updateIndexes.append(.init(id: result.recordName, version: indexes.version, indexes: indexes.indexes, checksum: indexes.checksum))
//                            }
//                        } else {
//                            _newIndexes.append(indexes)
//                        }
//                    }
//                    let newIndexes = _newIndexes
//                    let updateIndexes = _updateIndexes
//                    let deleteIndexes = cloudIndexes.map { ResourceIndexes(id: $0.recordName, version: $0.version, indexes: [:], checksum: $0.indexes.fileChecksum) }
//                    DispatchQueue.main.async {
//                        subscriber.send(.setNewIndexes(newIndexes))
//                        subscriber.send(.setDeleteIndexes(deleteIndexes))
//                        subscriber.send(.setUpdateIndexes(updateIndexes))
//                    }
//
//                    // Resources
//                    // load production data from cloud kit
//                    var cloudResources = try await env.cktool.queryResourceRecords()
//                    print(cloudResources.map { $0.name })
//                    // load development data from local database
//                    let localResources: [Resource] = try env.database.query()
//                    var _newResources: [Resource] = []
//                    var _updateResources: [Resource] = []
//                    localResources.forEach { resource in
//                        if let resultIndex = cloudResources.firstIndex(where: { $0.recordName == resource.id }) {
//                            let result = cloudResources.remove(at: resultIndex)
//                            if resource.checksum != result.asset.fileChecksum {
//                                _updateResources.append(.init(id: result.recordName, name: resource.name, version: resource.version, pathExtension: resource.pathExtension, checksum: resource.checksum))
//                            }
//                        } else {
//                            _newResources.append(resource)
//                        }
//                    }
//                    let newResources = _newResources
//                    let updateResources = _updateResources
//                    let deleteResources = cloudResources.map { Resource(id: $0.recordName, name: $0.name, version: $0.version, pathExtension: $0.pathExtension, checksum: $0.asset.fileChecksum) }
//                    DispatchQueue.main.async {
//                        subscriber.send(.setDeploying(true))
//                        subscriber.send(.setNewResources(newResources))
//                        subscriber.send(.setDeleteResources(deleteResources))
//                        subscriber.send(.setUpdateResources(updateResources))
//
//                        env.cktool.configureEnvironment(configure.containerId, environment: "DEVELOPMENT", ckAPIToken: configure.developmentCKAPIToken, ckWebAuthToken: configure.developmentCKWebAuthToken)
//                    }
//                } catch {
//                    DispatchQueue.main.async {
//                        subscriber.send(.setError(error.toString()))
//                        subscriber.send(.setDeploying(false))
//
//                        env.cktool.configureEnvironment(configure.containerId, environment: "DEVELOPMENT", ckAPIToken: configure.developmentCKAPIToken, ckWebAuthToken: configure.developmentCKWebAuthToken)
//                    }
//                }
//            }
            
            return AnyCancellable {}
        }
    case .cancel:
        state.isDeploying = false
    case .deploy:
        let newIndexes = state.newIndexes
        let updateIndexes = state.updateIndexes
        let newResources = state.newResources
        state.isLoading = true
        return Effect.run { subscriber in
//            Task {
//                do {
//                    let configure = env.database.loadCKToolConfiguration()
//                    DispatchQueue.main.sync {
//                        env.cktool.configureEnvironment(configure.containerId, environment: "PRODUCTION", ckAPIToken: configure.productionCKAPIToken, ckWebAuthToken: configure.productionCKWebAuthToken)
//                    }
//
//                    // Upload Indexes
//                    for item in newIndexes {
//                        let result = try await env.cktool.createResourceIndexRecord(indexes: item)
//                        print(result)
//                    }
//                    for item in updateIndexes {
//                        let result = try await env.cktool.updateResourceIndexRecord(indexes: item)
//                        print(result)
//                    }
//
//                    // Upload Resources
//                    for item in newResources {
//                        if let data = item.data() {
//                            let result = try await env.cktool.createAssetsRecord(recordName: item.id, name: item.name, version: item.version, pathExtension: item.pathExtension, asset: data)
//                            print(result)
//                        } else {
//                            debugPrint("\(item.name)-\(Version.intVersionToString(item.version)): data is nil")
//                        }
//                    }
//
//                    DispatchQueue.main.async {
//                        subscriber.send(.setLoading(false))
//                    }
//                } catch {
//                    DispatchQueue.main.async {
//                        subscriber.send(.setError(error.toString()))
//                    }
//                }
//
//                let configure = env.database.loadCKToolConfiguration()
//                DispatchQueue.main.sync {
//                    env.cktool.configureEnvironment(configure.containerId, environment: "DEVELOPMENT", ckAPIToken: configure.developmentCKAPIToken, ckWebAuthToken: configure.developmentCKWebAuthToken)
//                }
//            }
            return AnyCancellable {}
        }
    }
    
    return .none
}
