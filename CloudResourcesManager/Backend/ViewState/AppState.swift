//
//  AppState.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/2.
//

import Foundation
import ComposableArchitecture
import Combine

struct AppEnvironment {
    var mainQueue: AnySchedulerOf<DispatchQueue> {
        AnySchedulerOf<DispatchQueue>.main
    }
    
    let cktool: CKToolJS
    
    let database: Database
}

struct AppState: Equatable {
    var resourceIndexes: IdentifiedArrayOf<ResourceIndexState> = []
    var resources = ResourcesState()
    var createResource = CreateResourceState()
    var createResourceIndexes = CreateResourceIndexesState()
    var configuration = ConfigurationState()
    
    var loading: Bool = false
    var error: String = ""
}


typealias StateUpdater<T> = (_ state: inout T) -> Void

enum AppAction {
    case update(Result<StateUpdater<AppState>, Error>)
    case setError(String)
    case loadFromDB
    case loadFromCloud
    
    // Page
    case resourceIndexes(ResourceIndexes.ID, ResourceIndexAction)
    case resources(ResourcesAction)
    case createResource(CreateResourceAction)
    case createResourceIndexes(CreateResourceIndexesAction)
    case configuration(ConfigurationAction)
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.init { state, action, env in
    switch action {
    case .update(let result):
        switch result {
        case .success(let updater):
            updater(&state)
        case .failure(let error):
            state.error = error.toString()
        }
        return .none
    case .setError(let error):
        state.error = error
    case .loadFromDB:
        return loadFromDB(state, action, env)
    case .loadFromCloud:
        return loadFromCloud(state, action, env)
    
    // Page
    case .resources(let action):
        break
    case .createResource(let action):
        switch action {
        case .completionHandler(let result):
            if case .success(let value) = result {
                state.resources.resources.append(value)
            }
        default:
            break
        }
    case .createResourceIndexes(let action):
        switch action {
        case .completion(let result):
            state.resourceIndexes.insert(.init(index: result), at: 0)
            state.resourceIndexes.sort(by: { $0.index.version > $1.index.version })
        default:
            break
        }
    case .configuration(let action):
        break
    case .resourceIndexes(let id, let action):
        switch action {
        case .setActive(let value):
            if let index = state.resourceIndexes.firstIndex(where: { $0.id == id }) {
                var elements = state.resourceIndexes.elements
                if value {
                    elements[index].resources = state.resources.resources
                    state.resourceIndexes = .init(uniqueElements: elements)
                }
            }
        case .deleteCompletion:
            if let index = state.resourceIndexes.firstIndex(where: { $0.id == id }) {
                state.resourceIndexes.remove(at: index)
            }
        default:
            break
        }
    }
    return .none
}

func loadFromDB(_ state: AppState, _ action: AppAction, _ env: AppEnvironment) -> Effect<AppAction, Never> {
    return Effect.task {
        let cktoolConfiguration = env.database.loadCKToolConfiguration()
        let localAssets: [Resource] = try env.database.query()
        let localIndexes: [ResourceIndexes] = try env.database.query()
        return { (state: inout AppState) in
            state.configuration.containerId = cktoolConfiguration.containerId
            state.configuration.environment = .init(rawValue: cktoolConfiguration.environment) ?? .development
            state.configuration.userToken = cktoolConfiguration.userToken
            
            env.cktool.configureEnvironment(cktoolConfiguration.containerId, cktoolConfiguration.environment, cktoolConfiguration.userToken)
            
            state.resources.resources = localAssets
            
            state.resourceIndexes.append(contentsOf: localIndexes.map { ResourceIndexState(index: $0) })
        }
    }
    .receive(on: env.mainQueue)
    .catchToEffect(AppAction.update)
}

func loadFromCloud(_ state: AppState, _ action: AppAction, _ env: AppEnvironment) -> Effect<AppAction, Never> {
    let localAssets = state.resources.resources
    return .run { subscriber in
        Task {
            let records: [CKToolJS.AssetsRecord]
            do {
                records = try await env.cktool.queryResourceRecords()
            } catch {
                DispatchQueue.main.async {
                    subscriber.send(.setError(error.toString()))
                }
                return
            }
            
            let resources = await withTaskGroup(of: Resource.self, returning: [Resource].self) { group in
                records.forEach { record in
                    print("Add to group - \(record.recordName)")
                    group.addTask {
                        if let asset = localAssets.first(where: { $0.id == record.recordName && $0.checksum == record.asset.fileChecksum }), asset.hasLocalData(in: env.database.database()!) {
                            print("Skip - \(record.recordName)")
                            return asset
                        }
                        
                        let checksum: String
                        let urlString = record.asset.downloadUrl.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? record.asset.downloadUrl
                        if let url = URL(string: urlString) {
                            print("Downloading - \(record.recordName)")
                            do {
                                let data = try await AssetDownloader().download(url)
                                try Asset(id: record.recordName, data: data).save(to: env.database.database()!)
                                checksum = record.asset.fileChecksum
                            } catch {
                                print("Download failed - \(record.recordName)\n\(error)")
                                checksum = ""
                            }
                        } else {
                            print("Invalid URL - \(record.recordName)\n\(record.asset.downloadUrl)")
                            checksum = ""
                        }
                        return .init(id: record.recordName, name: record.name, version: record.version, pathExtension: record.pathExtension, checksum: checksum)
                    }
                }
                var assets: [Resource] = []
                while let element = await group.next() {
                    assets.append(element)
                }
                return assets
            }
            
            try resources.save(to: Database.default.database()!)
            
            DispatchQueue.main.async {
                subscriber.send(.update(.success({ state in
                    state.resources.resources = resources
                })))
            }
        }
        return AnyCancellable {
        }
    }
}
