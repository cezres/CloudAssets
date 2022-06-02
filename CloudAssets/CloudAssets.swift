//
//  CloudAssets.swift
//  CloudAssets
//
//  Created by azusa on 2022/5/30.
//

import Foundation
import CloudKit
import UIKit
import SQLite3

public class CloudAssets {    
    private(set) var container: CKContainer!
    private(set) var version: Int!
    let cachesDirectory: URL
    let queue = OperationQueue()
    let group = DispatchGroup()
    
    public static let shared = CloudAssets()
    
    private var indexs: AssetIndexs?
    
    private init() {
        cachesDirectory = .init(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0], isDirectory: true).appendingPathComponent("cache_assets")
        
        var isDirectory: ObjCBool = false
        if !FileManager.default.fileExists(atPath: cachesDirectory.path, isDirectory: &isDirectory) || !isDirectory.boolValue {
            try? FileManager.default.createDirectory(at: cachesDirectory, withIntermediateDirectories: false, attributes: nil)
        }
        
        queue.name = "CloudAssets"
        queue.maxConcurrentOperationCount = 4
        queue.qualityOfService = .default
        
        // 网络状态
    }
    
    public func start(identifier: String, version: Int) {
        self.container = .init(identifier: identifier)
        self.version = version
        queryAssetIndexs(version: version)
    }
    
    func fetchRecordIdFromAssetIndexs(with name: String) -> CKRecord.ID? {
        if indexs == nil {
            group.wait()
            queryAssetIndexs(version: version)
            group.wait()
        }
        
        guard let recordName = indexs?[name] else { return nil }
        return .init(recordName: recordName)
    }
    
    func queryAssetIndexs(version: Int) {
        guard indexs == nil else {
            return
        }
        group.enter()
        
        let recordName = "asset_indexs"
        let localUrl = cachesDirectory.appendingPathComponent(recordName)
        var isLeave = false
        // Load from local
        if
            let data = try? Data(contentsOf: localUrl),
            let indexs = try? JSONDecoder().decode(AssetIndexs.self, from: data)
        {
            self.indexs = indexs
            group.leave()
            isLeave = true
            
            if indexs.version == version {
                return
            }
        }
        
        // Load from cloud
        let query = CKQuery(recordType: "AssetIndexs", predicate: .init(format: "version <= \(version)"))
        query.sortDescriptors = [
            .init(key: "version", ascending: false)
        ]
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1
        operation.desiredKeys = [
            "version"
        ]
        operation.recordFetchedBlock = { record in
            guard let version = record["version"] as? Int, version != self.indexs?.version else { return }
            self.container.publicCloudDatabase.fetch(withRecordID: record.recordID) { record, error in
                guard let indexsAsset = record?["indexs"] as? CKAsset, let url = indexsAsset.fileURL, let data = try? Data(contentsOf: url), let indexs = try? JSONDecoder().decode(AssetIndexs.self, from: data) else { return }
                self.indexs = indexs
                try? data.write(to: localUrl)
                
                if !isLeave {
                    self.group.leave()
                    isLeave = true
                }
            }
        }
        operation.queryCompletionBlock = { (cursor, error) in
            if let error = error {
                debugPrint(error)
                if !isLeave {
                    self.group.leave()
                    isLeave = true
                }
            }
        }
        container.publicCloudDatabase.add(operation)
    }
    
    public func fetch(withAssetName name: String, completionHandler: @escaping (_ data: Data?, _ error: Error?) -> Void) -> Operation {
        let op = BlockOperation {
            /// 在索引中查询资源ID，并使用资源ID直接获取数据
            if let recordId = self.fetchRecordIdFromAssetIndexs(with: name) {
                self.fetch(recordId: recordId, completionHandler: completionHandler)
            } else {
                /// 查询名称符合并且版本号最接近的资源
                let semaphore = DispatchSemaphore(value: 0)
                self.query(name: name, version: self.version) { data, error in
                    completionHandler(data, error)
                    semaphore.signal()
                }
                semaphore.wait()
            }
        }
        queue.addOperation(op)
        return op
    }
    
    private func query(name: String, version: Int, completionHandler: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        let query = CKQuery(recordType: "Assets", predicate: .init(format: "name == %@ && version <= %@", name, version))
        query.sortDescriptors = [
            .init(key: "version", ascending: false)
        ]
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1
        operation.desiredKeys = [
            "name", "version"
        ]
        operation.recordFetchedBlock = { record in
            self.fetch(recordId: record.recordID, completionHandler: completionHandler)
        }
        operation.queryCompletionBlock = { (cursor, error) in
            if let error = error {
                completionHandler(nil, error)
            }
        }
        container.publicCloudDatabase.add(operation)
    }
    
    private func fetch(recordId: CKRecord.ID, completionHandler: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        let localUrl = cachesDirectory.appendingPathComponent(recordId.recordName)
        
        @discardableResult func fetchFromLocal() -> Bool {
            if let data = try? Data(contentsOf: localUrl) {
                completionHandler(data, nil)
                return true
            } else {
                return false
            }
        }
        
        func fetchFromCloud() {
            container.publicCloudDatabase.fetch(withRecordID: recordId) { record, error in
                if let record = record, let asset = record["asset"] as? CKAsset, let url = asset.fileURL, let data = try? Data(contentsOf: url) {
                    try? data.write(to: localUrl)
                    completionHandler(data, nil)
                } else if let error = error {
                    completionHandler(nil, error)
                } else {
                    completionHandler(nil, NSError(domain: "", code: -1, userInfo: [:]))
                }
            }
        }
        
        if !fetchFromLocal() {
            fetchFromCloud()
        }
    }
}

struct AssetIndexs: Codable {
    typealias AssetId = String
    typealias AssetName = String
    
    struct Imageset: Codable {
        let x2: AssetId
        let x3: AssetId
    }
    
    let version: Int
    let datas: [AssetName: AssetId]
    let images: [AssetName: Imageset]
    
    var isEmpty: Bool {
        datas.isEmpty || images.isEmpty
    }
    
    subscript(assetName: AssetName) -> AssetId? {
        if let assetId = datas[assetName] {
            return assetId
        } else if let imageset = images[assetName] {
            switch Int(UIScreen().scale) {
            case 2:
                return imageset.x2
            case 3:
                return imageset.x3
            default:
                return imageset.x3
            }
        }
        return nil
    }
}
