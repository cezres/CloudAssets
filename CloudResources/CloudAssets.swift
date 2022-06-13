//
//  CloudAssets.swift
//  CloudResources
//
//  Created by azusa on 2022/6/12.
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
    
    private var indexes: LocalResourceIndexes?
    
    private init() {
        cachesDirectory = .init(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0], isDirectory: true).appendingPathComponent("cache_assets")
        
        var isDirectory: ObjCBool = false
        if !FileManager.default.fileExists(atPath: cachesDirectory.path, isDirectory: &isDirectory) || !isDirectory.boolValue {
            try? FileManager.default.createDirectory(at: cachesDirectory, withIntermediateDirectories: false, attributes: nil)
        }
        
        queue.name = "CloudResources"
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
        if indexes == nil {
            group.wait()
            queryAssetIndexs(version: version)
            group.wait()
        }
        
        guard let recordName = indexes?.indexes[name]?.id else { return nil }
        return .init(recordName: recordName)
    }
    
    func queryAssetIndexs(version: Int) {
        guard indexes == nil else {
            return
        }
        group.enter()
        
        let recordName = "resourc_indexes"
        let localUrl = cachesDirectory.appendingPathComponent(recordName)
        var isLeave = false
        // Load from local
        if
            let data = try? Data(contentsOf: localUrl),
            let localIndexes = try? JSONDecoder().decode(LocalResourceIndexes.self, from: data)
        {
            self.indexes = localIndexes
            group.leave()
            isLeave = true
            
//            if localIndexes.version == version {
//                return
//            }
        }
        
        // Load from cloud
        let query = CKQuery(recordType: "ResourceIndex", predicate: .init(format: "version <= \(version)"))
        query.sortDescriptors = [
            .init(key: "version", ascending: false)
        ]
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1
        operation.desiredKeys = [
            "version"
        ]
        operation.recordFetchedBlock = { record in
            guard
                let version = record["version"] as? Int,
                version != self.indexes?.version || self.indexes?.modifiedTimestamp != record.modificationDate?.timeIntervalSince1970
            else { return }
            self.container.publicCloudDatabase.fetch(withRecordID: record.recordID) { record, error in
                guard
                    let indexsAsset = record?["indexes"] as? CKAsset,
                    let version = record?["version"] as? Int,
                    let url = indexsAsset.fileURL,
                    let data = try? Data(contentsOf: url),
                    let indexs = try? JSONDecoder().decode(ResourceIndexes.self, from: data)
                else { return }
                self.indexes = .init(version: version, modifiedTimestamp: record?.modificationDate?.timeIntervalSince1970 ?? 0, indexes: indexs)
                
                do {
                    try JSONEncoder().encode(self.indexes).write(to: localUrl)
                } catch {
                    print(error)
                }
//                try? data.write(to: localUrl)
                
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

typealias ResourceName = String
typealias ResourceIndexes = [ResourceName: ResourceIndex]

struct LocalResourceIndexes: Codable {
    let version: Int
    let modifiedTimestamp: TimeInterval
    let indexes: ResourceIndexes
}

struct ResourceIndex: Codable {
    let id: String
}
