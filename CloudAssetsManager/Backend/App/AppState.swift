//
//  AppState.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/2.
//

import Foundation
import ComposableArchitecture
import Combine

let mainReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
    appReducer,
    createAssetReducer.pullback(state: \.createAsset, action: /AppAction.createAsset, environment: { $0 }),
    configurationReducer.pullback(state: \.configuration, action: /AppAction.configuration, environment: { $0 }),
    assetsReducer.pullback(state: \.resources, action: /AppAction.assets, environment: { $0 }),
    createResourceIndexReducer.pullback(state: \.createResourceIndex, action: /AppAction.createResourceIndex, environment: { $0 }),
    resourceIndexReducer.forEach(state: \.indexes, action: /AppAction.indexes, environment: { $0 })
)

struct AppEnvironment {
    var mainQueue: AnySchedulerOf<DispatchQueue> {
        AnySchedulerOf<DispatchQueue>.main
    }
    
    let cktool: CKToolJS
    
    let database: Database
}

struct AppState: Equatable {
    var indexes: IdentifiedArrayOf<ResourceIndexState> = []
    var loading: Bool = false
    
    // Page
    var resources = ResourcesState()
    var createAsset = CreateAssetState()
    var createResourceIndex = CreateResourceIndexState()
    var configuration = ConfigurationState()
}


typealias StateUpdater<T> = (_ state: inout T) -> Void

enum AppAction {
    case update(Result<StateUpdater<AppState>, Error>)
    case loadFromDB
    case loadFromCloud
    
    // Page
    case indexes(ResourceIndex.ID, ResourceIndexAction)
    case assets(ResourcesAction)
    case createAsset(CreateAssetAction)
    case createResourceIndex(CreateResourceIndexAction)
    case configuration(ConfigurationAction)
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.init { state, action, env in
    switch action {
    case .update(let result):
        switch result {
        case .success(let updater):
            updater(&state)
        case .failure(let error):
            debugPrint(error)
        }
        return .none
    case .loadFromDB:
        return loadFromDB(state, action, env)
    case .loadFromCloud:
        return loadFromCloud(state, action, env)
    
    // Page
    case .assets(let action):
        break
    case .createAsset(let action):
        switch action {
        case .completionHandler(let result):
            if case .success(let value) = result {
                state.resources.resources.append(value)
            }
        default:
            break
        }
    case .createResourceIndex(let action):
        switch action {
        case .completion(let result):
            if case .success(let value) = result {
                state.indexes.insert(.init(index: value), at: 0)
                state.indexes.sort(by: { $0.index.version > $1.index.version })
            }
        default:
            break
        }
    case .configuration(let action):
        break
    case .indexes(let id, let action):
        switch action {
        case .setActive(let value):
            if let index = state.indexes.firstIndex(where: { $0.id == id }) {
                var elements = state.indexes.elements
                if value {
                    elements[index].resources = state.resources.resources
                    state.indexes = .init(uniqueElements: elements)
                }
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
        let localIndexes: [ResourceIndex] = try env.database.query()
        return { (state: inout AppState) in
            state.configuration.containerId = cktoolConfiguration.containerId
            state.configuration.environment = .init(rawValue: cktoolConfiguration.environment) ?? .development
            state.configuration.userToken = cktoolConfiguration.userToken
            
            env.cktool.configureEnvironment(cktoolConfiguration.containerId, cktoolConfiguration.environment, cktoolConfiguration.userToken)
            
            state.resources.resources = localAssets
            
            state.indexes.append(contentsOf: localIndexes.map { ResourceIndexState(index: $0) })
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
                print(records)
            } catch {
                debugPrint(error)
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
