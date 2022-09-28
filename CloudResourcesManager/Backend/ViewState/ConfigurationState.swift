//
//  ConfigurationState.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/8.
//

import Foundation
import ComposableArchitecture
import SQLiteExt
import SQLite

struct ConfigurationState: Equatable, SQLiteTable, SQLiteTablePrimaryKey, Hashable {
    
    static var fields: [AnySQLiteField<ConfigurationState>] = [
        .init(identifier: "containerId", keyPath: \.containerId),
        .init(identifier: "developmentServerKeyID", keyPath: \.developmentServerKeyID),
        .init(identifier: "developmentServerKey", keyPath: \.developmentServerKey),
        .init(identifier: "productionServerKeyID", keyPath: \.productionServerKeyID),
        .init(identifier: "productionServerKey", keyPath: \.productionServerKey),
    ]
    
    static var primary: SQLiteFild<ConfigurationState, Int> = .init(identifier: "id", keyPath: \.id)
    
    var containerId: String = ""
    var developmentServerKeyID: String = ""
    var developmentServerKey: String = ""
    var productionServerKeyID = ""
    var productionServerKey = ""
    var id = 100
    
    var hashValueInLocalDatabase = 0
    var isAbleToUpdate = false
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(containerId)
        hasher.combine(developmentServerKeyID)
        hasher.combine(developmentServerKey)
        hasher.combine(productionServerKeyID)
        hasher.combine(productionServerKey)
    }
    
    static func load(from db: Connection) throws -> ConfigurationState {
        var result: ConfigurationState = try db.query().first ?? .init()
        result.hashValueInLocalDatabase = result.hashValue
        return result
    }
}

enum ConfigurationAction {
    case setContainerId(String)
    case setDevelopmentServerKeyID(String)
    case setDevelopmentServerKey(String)
    case setProductionServerKeyID(String)
    case setProductionServerKey(String)
    
    case update
}

let configurationReducer = Reducer<ConfigurationState, ConfigurationAction, AppEnvironment>.init { state, action, env in
    switch action {
    case .update:
        do {
            try env.localDatabase.insert(state)
            state.hashValueInLocalDatabase = state.hashValue
        } catch {
            debugPrint(error)
        }
    case .setContainerId(let value):
        state.containerId = value
    case .setDevelopmentServerKeyID(let value):
        state.developmentServerKeyID = value
    case .setDevelopmentServerKey(let value):
        state.developmentServerKey = value
    case .setProductionServerKeyID(let value):
        state.productionServerKeyID = value
    case .setProductionServerKey(let value):
        state.productionServerKey = value
    }
    state.isAbleToUpdate = state.hashValue != state.hashValueInLocalDatabase
    return .none
}
