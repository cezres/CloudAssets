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
    var developmentCKAPIToken: String = ""
    var developmentCKWebAuthToken: String = ""
    var productionCKAPIToken = ""
    var productionCKWebAuthToken = ""
    
    var isActive: Bool = false
    var isChanged: Bool = false
    var isLoading: Bool = false
    var error: String = ""
    
    enum Environment: String, Hashable, Identifiable {
        var id: String { rawValue }
        
        case development = "DEVELOPMENT"
        case production = "PRODUCTION"
    }
}

enum ConfigurationAction {
    case setContainerId(String)
    case setDevelopmentCKAPIToken(String)
    case setDevelopmentCKWebAuthToken(String)
    case setProductionCKAPIToken(String)
    case setProductionCKWebAuthToken(String)
    case setLoading(Bool)
    case setError(String)
    
    case update
}

let configurationReducer = Reducer<ConfigurationState, ConfigurationAction, AppEnvironment>.init { state, action, env in
    switch action {
    case .update:
        guard !state.containerId.isEmpty || !state.developmentCKAPIToken.isEmpty else {
            break
        }
        do {
            try env.database.saveCKToolConfiguration(.init(containerId: state.containerId, developmentCKAPIToken: state.developmentCKAPIToken, developmentCKWebAuthToken: state.developmentCKWebAuthToken, productionCKAPIToken: state.productionCKAPIToken, productionCKWebAuthToken: state.productionCKWebAuthToken))
        } catch {
            state.error = error.toString()
        }
        
        guard !state.developmentCKAPIToken.isEmpty else {
            break
        }
        env.cktool.configureEnvironment(state.containerId, environment: ConfigurationState.Environment.development.rawValue, ckAPIToken: state.developmentCKAPIToken, ckWebAuthToken: state.developmentCKWebAuthToken)
    case .setContainerId(let value):
        state.containerId = value
        
    case .setDevelopmentCKAPIToken(let value):
        state.developmentCKAPIToken = value
    case .setDevelopmentCKWebAuthToken(let value):
        state.developmentCKWebAuthToken = value
    case .setProductionCKAPIToken(let value):
        state.productionCKAPIToken = value
    case .setProductionCKWebAuthToken(let value):
        state.productionCKWebAuthToken = value
    case .setError(let value):
        state.error = value
    case .setLoading(let value):
        state.isLoading = value
    }
//    state.isChanged = env.cktool.configurationToken != CKToolConfiguration(containerId: state.containerId, environment: state.environment.rawValue, userToken: state.userToken).token()
    return .none
}
