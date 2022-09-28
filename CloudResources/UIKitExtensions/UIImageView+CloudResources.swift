//
//  UIImageView+CloudResources.swift
//  CloudResources
//
//  Created by azusa on 2022/6/12.
//

import Foundation
import UIKit

public extension UIImageView {
    @discardableResult
    func setCloudAsset(name: String) -> Task<Void, Never> {
        Task.detached {
            do {
                let url = try await CloudResources.shared.fetchResourceURL(name)
                if let image = UIImage(contentsOfFile: url.path) {
                    await MainActor.run {
                        self.image = image
                    }
                }
            } catch {
                debugPrint(error)
            }
        }
    }
    
    func setCloudAssetFromLocal(name: String) {
        guard
            let url = CloudResources.shared.fetchResourceUrlFromLocal(name),
            let image = UIImage(contentsOfFile: url.path)
        else {
            return
        }
        self.image = image
    }
}

extension Task {
    func cancel(whenObjectReleased object: NSObject, file: String = #file, line: Int = #line) {
        let key = "\(file)-\(line)"
        object.setReleaseAction({
            self.cancel()
        }, for: key)
        
        Task<Void, Never>.detached {
            let result = await self.result
            debugPrint(result)
            object.removeReleaseAction(for: key)
        }
    }
}

extension NSObject {
    func task<Success>(priority: TaskPriority? = nil, operation: @escaping @Sendable () async -> Success) -> Task<Success, Never> {
        let task = Task.detached(priority: priority, operation: operation)
        task.cancel(whenObjectReleased: self)
        return task
    }
}


private var __releaseProxyAssociatedKey: Int = 0

extension NSObject {
    
    class ReleaseProxy: NSObject {
        
        typealias Action = () -> Void
        
        var actions: [String: Action] = [:]
        
        deinit {
            for action in actions.values {
                action()
            }
        }
    }
    
    func setReleaseAction(_ action: @escaping () -> Void, for key: String) {
        __releaseProxy.actions[key] = action
    }
    
    func removeReleaseAction(for key: String) {
        __releaseProxy.actions.removeValue(forKey: key)
    }
    
    var __releaseProxy: ReleaseProxy {
        get {
            var proxy: ReleaseProxy
            if let result = objc_getAssociatedObject(self, &__releaseProxyAssociatedKey) as? ReleaseProxy {
                proxy = result
            } else {
                proxy = .init()
                objc_setAssociatedObject(self, &__releaseProxyAssociatedKey, proxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            return proxy
        }
    }
}
