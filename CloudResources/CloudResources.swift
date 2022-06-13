//
//  CloudResources.swift
//  CloudResources
//
//  Created by azusa on 2022/6/10.
//

import Foundation
import CloudKit
import CloudResourcesFoundation

public class CloudResources {
    public static let shared = CloudResources()
    
    private(set) var container: CKContainer!
    private(set) var version: Int!
    let cachesDirectory: URL
    
    private var queue = OperationQueue()
    private var resourceIndexesRecord: ResourceIndexesRecord?
    private var queryResourceIndexesGroup = DispatchGroup()
    
    init() {
        cachesDirectory = .init(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0], isDirectory: true).appendingPathComponent("cache_assets")
        
        queue.name = "CloudResources"
        queue.maxConcurrentOperationCount = 4
        queue.qualityOfService = .default
        
        // 网络状态
    }
    
    public func start(identifier: String, version: String) {
        guard let version = Version.stringVersionToInt(version) else {
            fatalError("Invalid version number")
        }
        self.container = .init(identifier: identifier)
        self.version = version
        queryResourceIndexes()
    }
}

extension CloudResources {
    enum CloudResourcesError: LocalizedError {
        case uninitialized
        case cloudError(Error?)
    }
}

extension CloudResources {
    @discardableResult
    func fetchResource(_ name: String, completionHandler: @escaping (_ data: Data?, _ error: Error?) -> Void) -> Operation {
        let op = BlockOperation {
            /// 在索引中查询资源ID，并使用资源ID直接获取数据
            if let recordId = self.queryResourceRecordId(resourceName: name) {
                self.fetchResource(recordId: recordId, completionHandler: completionHandler)
            } else {
                /// 查询名称符合并且版本号最接近的资源
                let semaphore = DispatchSemaphore(value: 0)
                self.queryResource(name: name, version: self.version) { data, error in
                    completionHandler(data, error)
                    semaphore.signal()
                }
                semaphore.wait()
            }
        }
        queue.addOperation(op)
        return op
    }
}

extension CloudResources {
    func queryResourceRecordId(resourceName: String) -> CKRecord.ID? {
        if resourceIndexesRecord == nil {
            queryResourceIndexesGroup.wait()
            queryResourceIndexes()
            queryResourceIndexesGroup.wait()
        }
        
        guard let recordName = resourceIndexesRecord?.indexes[resourceName]?.id else { return nil }
        return .init(recordName: recordName)
    }
    
    func queryResourceIndexes() {
        guard let database = container?.publicCloudDatabase else {
            return
        }
        guard resourceIndexesRecord == nil else {
            return
        }
        guard let version = version else {
            return
        }
        queryResourceIndexesGroup.enter()
        
        let recordName = "resourc_indexes"
        let localUrl = cachesDirectory.appendingPathComponent(recordName)
        var isLeave = false
        // Load from local
        if
            let data = try? Data(contentsOf: localUrl),
            let localIndexes = try? JSONDecoder().decode(ResourceIndexesRecord.self, from: data)
        {
            self.resourceIndexesRecord = localIndexes
            self.queryResourceIndexesGroup.leave()
            isLeave = true
        }
        
        // Load from cloud
        let query = CKQuery(recordType: "ResourceIndexes", predicate: .init(format: "version <= \(version)"))
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
                version != self.resourceIndexesRecord?.version || self.resourceIndexesRecord?.modifiedTimestamp != record.modificationDate?.timeIntervalSince1970
            else { return }
            self.container.publicCloudDatabase.fetch(withRecordID: record.recordID) { record, error in
                guard
                    let record = record,
                    let indexsAsset = record["indexes"] as? CKAsset,
                    let version = record["version"] as? Int,
                    let url = indexsAsset.fileURL,
                    let data = try? Data(contentsOf: url),
                    let indexes = try? JSONDecoder().decode(ResourceIndexes.self, from: data)
                else { return }
                self.resourceIndexesRecord = .init(recordName: record.recordID.recordName, modifiedTimestamp: record.modificationDate?.timeIntervalSince1970 ?? 0, version: version, indexes: indexes)
                
                do {
                    try JSONEncoder().encode(self.resourceIndexesRecord).write(to: localUrl)
                } catch {
                    print(error)
                }
                
                if !isLeave {
                    self.queryResourceIndexesGroup.leave()
                    isLeave = true
                }
            }
        }
        operation.queryCompletionBlock = { (cursor, error) in
            if let error = error {
                debugPrint(error)
                if !isLeave {
                    self.queryResourceIndexesGroup.leave()
                    isLeave = true
                }
            }
        }
        database.add(operation)
    }
}

extension CloudResources {
    func fetchResource(recordId: CKRecord.ID, completionHandler: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        guard let database = container?.publicCloudDatabase else {
            completionHandler(nil, CloudResourcesError.uninitialized)
            return
        }
        
        let localUrl = cachesDirectory.appendingPathComponent(recordId.recordName)
        
        if let data = try? Data(contentsOf: localUrl) {
            completionHandler(data, nil)
        } else {
            database.fetch(withRecordID: recordId) { record, error in
                guard
                    let record = record,
                    let asset = record["asset"] as? CKAsset,
                    let url = asset.fileURL,
                    let data = try? Data(contentsOf: url)
                else {
                    completionHandler(nil, CloudResourcesError.cloudError(error))
                    return
                }
                completionHandler(data, nil)
            }
        }
    }
    
    func queryResource(name: String, version: Int, completionHandler: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        guard let database = container?.publicCloudDatabase else {
            completionHandler(nil, CloudResourcesError.uninitialized)
            return
        }
        
        let success = { (record: CKRecord) in
            completionHandler(nil, nil)
        }
        let failure = { (error: Error) in
            completionHandler(nil, CloudResourcesError.cloudError(error))
        }
        
        let query = CKQuery(
            recordType: "Resource",
            predicate: .init(format: "name == %@ && version <= %@", name, version)
        )
        query.sortDescriptors = [
            .init(key: "version", ascending: false)
        ]
        let desiredKeys = ["name", "version"]
        let resultsLimit = 1
        
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = resultsLimit
        operation.desiredKeys = desiredKeys
        operation.recordFetchedBlock = { record in
            success(record)
        }
        operation.queryCompletionBlock = { (cursor, error) in
            if let error = error {
                failure(error)
            }
        }
        database.add(operation)
    }
}
