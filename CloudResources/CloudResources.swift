//
//  CloudResources.swift
//  CloudResources
//
//  Created by azusa on 2022/6/10.
//

import Foundation
import CloudKit

private var queryResourceIndexesGroup = DispatchGroup()

public class CloudResources {
    
    typealias FetchResourceCompletionHandler = (_ result: Result<URL, Error>) -> Void
    
    struct TodoTask {
        let name: String
        var handlers: [FetchResourceCompletionHandler]
    }
    
    public static let shared = CloudResources()
    
    private(set) var container: CKContainer!
    private(set) var version: Int!
    let cachesDirectory: URL
    
    @MainActor var xxx: Int = 0
    
    private var resourceIndexesRecord: ResourceIndexesRecord?
    
//    private var fetchingList: [String: [FetchResourceCompletionHandler]] = [:]
//    private var todoList: [TodoTask] = []
//    private let maxConcurrentOperationCount = 3
    
    private var queue: CloudResourcesOperationQueue<String, Result<URL, Error>>!
    
    init() {
        cachesDirectory = .init(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0], isDirectory: true).appendingPathComponent("cache_assets")
        
        var isDirectory: ObjCBool = false
        if !FileManager.default.fileExists(atPath: cachesDirectory.path, isDirectory: &isDirectory) || !isDirectory.boolValue {
            do {
                try FileManager.default.createDirectory(at: cachesDirectory, withIntermediateDirectories: false)
            } catch {
                debugPrint(error)
            }
        }
    }
        
//    nonisolated
    public func start(identifier: String, version: String) {
        guard let version = Version.stringVersionToInt(version) else {
            fatalError("Invalid version number")
        }
        self.container = .init(identifier: identifier)
        self.version = version
        
        queue = .init(maxConcurrentCount: 4, check: {
            self.resourceIndexesRecord != nil
        }, handler: { op in
            do {
                let url = try await self._fetchResourceURL(op)
                return .success(url)
            } catch {
                return .failure(error)
            }
        })
        
        self.queryResourceIndexes()
    }
    
    func queryResourceIndexesCompleted() {
        guard let keys = resourceIndexesRecord?.indexes.keys.reversed() else { return }
        Task.detached(priority: .background) {
//            queryResourceIndexesGroup.wait()
            await withThrowingTaskGroup(of: Void.self) { group in
                (["wallet_chain_background_ethereum", "wallet_chain_background_bytom", "wallet_chain_background_bsc", "wallet_chain_background_litecoin"] + keys).forEach { name in
                    group.addTask {
                        let url = try await self.fetchResourceURL(name)
                        print("预加载完成 - \(name) - \(url.lastPathComponent)")
                    }
                }
            }
        }
    }
}

extension CloudResources {
    enum CloudResourcesError: LocalizedError {
        case uninitialized
        case cloudError(Error?)
    }
}

extension CloudResources {
    public func fetchResourceUrlFromLocal(_ name: String) -> URL? {
        guard let indexes = resourceIndexesRecord?.indexes else {
            return nil
        }
        if let recordName = indexes[name]?.id {
            let localUrl = cachesDirectory.appendingPathComponent(recordName)
            return FileManager.default.fileExists(atPath: localUrl.path) ? localUrl : nil
        } else {
            return nil
        }
    }
    
    public func fetchResourceURL(_ name: String) async throws -> URL {
        return try await queue.insert(op: name).get()
    }
    
    private func _fetchResourceURL(_ name: String) async throws -> URL {
        /// 在索引中查询资源ID，并使用资源ID直接获取数据
        if let recordId = self.queryResourceRecordId(resourceName: name) {
            return try await self.fetchResourceURL(recordId: recordId)
        } else {
            /// 查询名称符合并且版本号最接近的资源
            return try await self.queryResourceURL(name: name, version: self.version)
        }
    }
}

// MARK: - Resource Indexs
extension CloudResources {
    func queryResourceRecordId(resourceName: String) -> CKRecord.ID? {
        queryResourceIndexesGroup.wait()
        if resourceIndexesRecord == nil {
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
            queryResourceIndexesGroup.leave()
            isLeave = true
            self.queryResourceIndexesCompleted()
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
            else {
                if !isLeave {
                    queryResourceIndexesGroup.leave()
                    isLeave = true
                    self.queryResourceIndexesCompleted()
                }
                return
            }
            self.container.publicCloudDatabase.fetch(withRecordID: record.recordID) { record, error in
                defer {
                    if !isLeave {
                        queryResourceIndexesGroup.leave()
                        isLeave = true
                        self.queryResourceIndexesCompleted()
                    }
                }
                
                guard
                    let record = record,
                    let indexsAsset = record["indexes"] as? CKAsset,
                    let version = record["version"] as? Int,
                    let url = indexsAsset.fileURL,
                    let data = try? Data(contentsOf: url),
                    let indexes = try? JSONDecoder().decode(ResourceIndexes.self, from: data)
                else {
                    return
                }
                self.resourceIndexesRecord = .init(recordName: record.recordID.recordName, modifiedTimestamp: record.modificationDate?.timeIntervalSince1970 ?? 0, version: version, indexes: indexes)
                
                do {
                    try JSONEncoder().encode(self.resourceIndexesRecord).write(to: localUrl)
                } catch {
                    print(error)
                }
            }
        }
        operation.queryCompletionBlock = { (cursor, error) in
            if let error = error {
                debugPrint(error)
            } else if let cursor = cursor {
                return
            }
            if !isLeave {
                queryResourceIndexesGroup.leave()
                isLeave = true
                self.queryResourceIndexesCompleted()
            }
        }
        database.add(operation)
    }
}
// MARK: - Resource
extension CloudResources {
    private func fetchResourceURL(recordId: CKRecord.ID) async throws -> URL {
        guard let database = container?.publicCloudDatabase else {
            throw CloudResourcesError.uninitialized
        }
        
        let localUrl = cachesDirectory.appendingPathComponent(recordId.recordName)
        
        if FileManager.default.fileExists(atPath: localUrl.path) {
            return localUrl
        } else {
            let record = try await database.record(for: recordId)
            
            guard
                let asset = record["asset"] as? CKAsset,
                let url = asset.fileURL,
                let data = try? Data(contentsOf: url)
            else {
                throw CloudResourcesError.cloudError(nil)
            }
            
            do {
                try data.write(to: localUrl)
            } catch {
                throw error
            }
            return localUrl
        }
    }
    
    func queryResourceURL(name: String, version: Int) async throws -> URL {
        guard let database = container?.publicCloudDatabase else {
            throw CloudResourcesError.uninitialized
        }
        
        let predicate = NSPredicate.init(format: "name == '\(name)' AND version <= \(version)")
        let query = CKQuery(
            recordType: "Resource",
            predicate: predicate
        )
        query.sortDescriptors = [
            .init(key: "version", ascending: false)
        ]
        let desiredKeys = ["name", "version", "asset"]
        let resultsLimit = 1
        
        return try await withUnsafeThrowingContinuation { (c: UnsafeContinuation<URL, Error>) in
            var callbacked = false
            
            let operation = CKQueryOperation(query: query)
            operation.resultsLimit = resultsLimit
            operation.desiredKeys = desiredKeys
            operation.recordFetchedBlock = { record in
                if let asset = record["asset"] as? CKAsset, let url = asset.fileURL {
                    c.resume(returning: url)
                    callbacked = true
                }
            }
            operation.queryCompletionBlock = { (cursor, error) in
                guard !callbacked else {
                    return
                }
                if let error = error {
                    c.resume(throwing: error)
                } else {
                    c.resume(throwing: NSError(domain: "Fail: queryResourceURL", code: -1))
                }
            }
            database.add(operation)
        }
    }
}
