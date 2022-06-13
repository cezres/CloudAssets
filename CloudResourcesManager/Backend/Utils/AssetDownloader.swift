//
//  AssetDownloader.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/6.
//

import Foundation

class AssetDownloader {
    
    static let shared = AssetDownloader()
    
    private var loading: [URL: Task<Data, Error>] = [:]
    
    init() {
        
    }
    
    func download(_ url: URL) async throws -> Data {
        let task: Task<Data, Error>
        if let _task = loading[url] {
            task = _task
        } else {
            task = .init(priority: .background, operation: {
                return try Data.init(contentsOf: url)
            })
            loading[url] = task
        }
        return try await task.value
    }
}
