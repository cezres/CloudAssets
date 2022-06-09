//
//  ResourceIndexState.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/9.
//

import Foundation
import ComposableArchitecture

struct ResourceIndexState: Equatable, Identifiable {
    var index: ResourceIndex
    
    var id: String { index.id }
    
    var resources: [Resource] = [] {
        didSet {
            guard resources != oldValue else { return }
            makeDataList()
        }
    }
    
    var isActive: Bool = false
    
    var leftList: [Resource] = []
    var rightList: [Resource] = []
}

extension ResourceIndexState {
    mutating func makeDataList() {
        var tempList = resources
        leftList = index.indexes.map { (key, value) -> Resource in
            if let index = tempList.firstIndex(where: { $0.id == value.id }) {
                return tempList.remove(at: index)
            } else {
                return Resource(id: "", name: key, version: 0, pathExtension: "", checksum: "")
            }
        }.sorted(by: { $0.name < $1.name })
        rightList = tempList.sorted(by: { $0.name < $1.name })
    }
}

enum ResourceIndexAction {
    case setActive(Bool)
    case tapLeft(Resource)
    case tapRight(Resource)
}

let resourceIndexReducer = Reducer<ResourceIndexState, ResourceIndexAction, AppEnvironment>.init { state, action, env in
    switch action {
    case .setActive(let value):
        state.isActive = value
    case .tapLeft(let value):
        if let index = state.leftList.firstIndex(of: value) {
            state.leftList.remove(at: index)
        }
        if !value.id.isEmpty {
            state.rightList.append(value)
        }
    case .tapRight(let value):
        if let index = state.rightList.firstIndex(of: value) {
            state.rightList.remove(at: index)
        }
        if !value.id.isEmpty {
            state.leftList.append(value)
        }
    }
    return .none
}

