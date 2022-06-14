//
//  MainReducer.swift
//  CloudResourcesManager
//
//  Created by azusa on 2022/6/13.
//

import Foundation
import ComposableArchitecture

let mainReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
    appReducer,
    createResourceReducer.pullback(state: \.createResource, action: /AppAction.createResource, environment: { $0 }),
    configurationReducer.pullback(state: \.configuration, action: /AppAction.configuration, environment: { $0 }),
    resourcesReducer.pullback(state: \.resources, action: /AppAction.resources, environment: { $0 }),
    createResourceIndexesReducer.pullback(state: \.createResourceIndexes, action: /AppAction.createResourceIndexes, environment: { $0 }),
    resourceIndexReducer.forEach(state: \.resourceIndexes, action: /AppAction.resourceIndexes, environment: { $0 })
)

