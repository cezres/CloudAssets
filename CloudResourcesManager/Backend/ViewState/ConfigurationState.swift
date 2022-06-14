//
//  ConfigurationState.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/8.
//

import Foundation
import ComposableArchitecture

struct ConfigurationState: Equatable {
    var containerId: String = ""
    var environment: Environment = .development
    var userToken: String = ""
    var isActive: Bool = false
    var isChanged: Bool = false
    var error: String = ""
    
    enum Environment: String, Hashable, Identifiable {
        var id: String { rawValue }
        
        case development = "DEVELOPMENT"
        case production = "PRODUCTION"
    }
}

enum ConfigurationAction {
    case setContainerId(String)
    case setEnvironment(ConfigurationState.Environment)
    case setUserToken(String)
    case setError(String)
    
    case update
}

let configurationReducer = Reducer<ConfigurationState, ConfigurationAction, AppEnvironment>.init { state, action, env in
    switch action {
    case .update:
        env.cktool.configureEnvironment(state.containerId, state.environment.rawValue, state.userToken)
        do {
            try env.database.saveCKToolConfiguration(state.containerId, state.environment.rawValue, state.userToken)
        } catch {
            state.error = error.toString()
        }
    case .setContainerId(let value):
        state.containerId = value
        
    case .setEnvironment(let value):
        state.environment = value
    case .setUserToken(let value):
        state.userToken = value
    case .setError(let value):
        state.error = value
    }
    state.isChanged = env.cktool.configurationToken != CKToolConfiguration(containerId: state.containerId, environment: state.environment.rawValue, userToken: state.userToken).token()
    return .none
}
