//
//  CloudResources.swift
//  CloudResources
//
//  Created by azusa on 2022/6/10.
//

import Foundation
import CloudKit
//import CloudResourcesFoundation

public class CloudResources {
    struct TodoTask {
        let name: String
        var handlers: [FetchResourceCompletionHandler]
    }
    
    typealias FetchResourceCompletionHandler = (_ url: URL?, _ error: Error?) -> Void
    
    public static let shared = CloudResources()
    
    private(set) var container: CKContainer!
    private(set) var version: Int!
    let cachesDirectory: URL
    
    private let syncQueue = OS_dispatch_queue_serial(label: "CloudResources")
    private var taskQueue = OperationQueue()
    private var queue = OperationQueue()
    private var resourceIndexesRecord: ResourceIndexesRecord?
    private var queryResourceIndexesGroup = DispatchGroup()
    
    private var fetchingList: [String: [FetchResourceCompletionHandler]] = [:]
    private var todoList: [TodoTask] = []
    private let maxConcurrentOperationCount = 2
    
    init() {
        cachesDirectory = .init(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0], isDirectory: true).appendingPathComponent("cache_assets")
        
//        try? FileManager.default.removeItem(at: cachesDirectory)
        
        var isDirectory: ObjCBool = false
        if !FileManager.default.fileExists(atPath: cachesDirectory.path, isDirectory: &isDirectory) || !isDirectory.boolValue {
            do {
                try FileManager.default.createDirectory(at: cachesDirectory, withIntermediateDirectories: false)
            } catch {
                debugPrint(error)
            }
        }
        
        taskQueue.name = "CloudResources"
        taskQueue.qualityOfService = .default
//        taskQueue.maxConcurrentOperationCount = 6
        
        queue.maxConcurrentOperationCount = 1
        
        // 网络状态
    }
    
    public func start(identifier: String, version: String) {
        guard let version = Version.stringVersionToInt(version) else {
            fatalError("Invalid version number")
        }
        self.container = .init(identifier: identifier)
        self.version = version
        queryResourceIndexes()
        
        DispatchQueue.global().async {
            self.queryResourceIndexesGroup.wait()

            guard let keys = self.resourceIndexesRecord?.indexes.keys.reversed() else { return }

            keys.forEach { resourceName in
                print(resourceName)
                self.fetchResourceURL(resourceName) { url, error in
                    print("预加载完成 - \(resourceName)")
                }
            }
        }
    }
    
    public func threadSafety(block: @escaping () -> Void) {
        syncQueue.async(group: nil, qos: .background, flags: .barrier, execute: block)
        
//        if Thread.current.name == "CloudResources" {
//            block()
//        } else {
//            syncQueue.async(group: nil, qos: .background, flags: .barrier) {
//                Thread.current.name = "CloudResources"
//                block()
//            }
//        }
    }
}

extension CloudResources {
    enum CloudResourcesError: LocalizedError {
        case uninitialized
        case cloudError(Error?)
    }
}

extension CloudResources {
    private func fetchResourceFromTodoList() {
        threadSafety {
            while self.fetchingList.count < self.maxConcurrentOperationCount && !self.todoList.isEmpty {
                let todo = self.todoList.removeLast()
                self.fetchingList[todo.name] = todo.handlers
                self._fetchResourceURL(todo.name) { url, error in
                    self.threadSafety {
                        if let handlers = self.fetchingList.removeValue(forKey: todo.name) {
                            handlers.forEach { $0(url, error) }
                        } else {
                            fatalError()
                        }
                        self.fetchResourceFromTodoList()
                    }
                }
            }
        }
    }
    
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
    
    public func fetchResourceURL(_ name: String, completionHandler: @escaping (_ url: URL?, _ error: Error?) -> Void) {
        threadSafety {
            if let list = self.fetchingList[name] {
                self.fetchingList[name] = list + [completionHandler]
                return
            }
            
            if let index = self.todoList.firstIndex(where: { $0.name == name }) {
                let handlers = self.todoList.remove(at: index).handlers + [completionHandler]
                self.todoList.append(.init(name: name, handlers: handlers))
            } else {
                self.todoList.append(.init(name: name, handlers: [completionHandler]))
            }
            
            self.fetchResourceFromTodoList()
        }
    }
    
    private func _fetchResourceURL(_ name: String, completionHandler: @escaping (_ url: URL?, _ error: Error?) -> Void) {
        let op = BlockOperation {
            /// 在索引中查询资源ID，并使用资源ID直接获取数据
            if let recordId = self.queryResourceRecordId(resourceName: name) {
                self.fetchResourceURL(recordId: recordId, completionHandler: completionHandler)
            } else {
                /// 查询名称符合并且版本号最接近的资源
                let semaphore = DispatchSemaphore(value: 0)
                self.queryResourceURL(name: name, version: self.version) { url, error in
                    completionHandler(url, error)
                    semaphore.signal()
                }
                semaphore.wait()
            }
        }
        taskQueue.addOperation(op)
    }
    
    public func fetchResource(_ name: String, completionHandler: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        fetchResourceURL(name) { url, error in
            if let url = url {
                completionHandler(try? Data(contentsOf: url), error)
            } else {
                completionHandler(nil, error)
            }
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
//            self.queryResourceIndexesGroup.leave()
//            isLeave = true
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
                    self.queryResourceIndexesGroup.leave()
                    isLeave = true
                }
                return
            }
            self.container.publicCloudDatabase.fetch(withRecordID: record.recordID) { record, error in
                defer {
                    if !isLeave {
                        self.queryResourceIndexesGroup.leave()
                        isLeave = true
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
            }
            if !isLeave {
                self.queryResourceIndexesGroup.leave()
                isLeave = true
            }
        }
        database.add(operation)
    }
}
// MARK: - Resource
extension CloudResources {
    func fetchResourceURL(recordId: CKRecord.ID, completionHandler: @escaping (_ url: URL?, _ error: Error?) -> Void) {
        guard let database = container?.publicCloudDatabase else {
            completionHandler(nil, CloudResourcesError.uninitialized)
            return
        }
        
        let localUrl = cachesDirectory.appendingPathComponent(recordId.recordName)
        
        if FileManager.default.fileExists(atPath: localUrl.path) {
            completionHandler(localUrl, nil)
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
                do {
                    try data.write(to: localUrl)
                    completionHandler(localUrl, nil)
                } catch {
                    completionHandler(nil, error)
                }
            }
        }
    }
    
    func queryResourceURL(name: String, version: Int, completionHandler: @escaping (_ url: URL?, _ error: Error?) -> Void) {
        guard let database = container?.publicCloudDatabase else {
            completionHandler(nil, CloudResourcesError.uninitialized)
            return
        }
        
        let success = { (record: CKRecord) in
            if let asset = record["asset"] as? CKAsset, let url = asset.fileURL {
                completionHandler(url, nil)
            } else {
                completionHandler(nil, nil)
            }
        }
        let failure = { (error: Error) in
            completionHandler(nil, CloudResourcesError.cloudError(error))
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
