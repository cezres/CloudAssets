//
//  ResourceItemState.swift
//  CloudResourcesManager
//
//  Created by 翟泉 on 2022/8/25.
//

import ComposableArchitecture
import Cocoa
import Combine

struct ResourceItemState: Equatable, Identifiable {
    var resource: Resource
    var image: NSImage?
    
    var id: String { resource.id }
}

enum ResourceItemAction {
    case loadThumbnail
    case loadingThumbnailComplete(NSImage)
}

let resourceItemReducer = Reducer<ResourceItemState, ResourceItemAction, AppEnvironment>.init { state, action, env in
    switch action {
    case .loadThumbnail:
        let resource = state.resource
        return Effect.run { subscriber in
            Task.detached {
                if let image = await resource.thumbnail(env.localDatabase) {
                    await MainActor.run {
                        subscriber.send(.loadingThumbnailComplete(image))
                    }
                }
            }
            return AnyCancellable {}
        }
    case .loadingThumbnailComplete(let result):
        state.image = result
    }
    return .none
}
