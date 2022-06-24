//
//  CloudResourcesOperationQueue.swift
//  CloudResources
//
//  Created by azusa on 2022/6/16.
//

import Foundation

class CloudResourcesOperationQueue {
    
    let queue = OperationQueue()
    
    init() {
        
    }
    
    func fetch(key: String, operation: @escaping () -> Void, completionHandler: @escaping (_ url: URL?, _ error: Error?) -> Void) {
        queue.operations
        
//        fetch(key: "11", operation: <#T##() -> Void#>, completionHandler: <#T##(URL?, Error?) -> Void##(URL?, Error?) -> Void##(_ url: URL?, _ error: Error?) -> Void#>)
        
    }
    
}
