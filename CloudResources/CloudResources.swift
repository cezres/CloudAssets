//
//  CloudResources.swift
//  CloudResources
//
//  Created by azusa on 2022/6/10.
//

import Foundation
import CloudKit

public class CloudResources {
    private(set) var container: CKContainer!
    private(set) var version: Int!
    let cachesDirectory: URL
    
    init() {
        cachesDirectory = .init(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0], isDirectory: true).appendingPathComponent("cache_assets")
    }
    
    public func start(identifier: String, version: Int) {
        self.container = .init(identifier: identifier)
        self.version = version
//        queryAssetIndexs(version: version)
    }
}

extension CloudResources {
    enum CloudResourcesError: LocalizedError {
        case uninitialized
        case cloudError(Error?)
    }
}

extension CloudResources {
    func searchResource(_ recordName: String, completionHandler: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        guard let database = container?.publicCloudDatabase else {
            completionHandler(nil, CloudResourcesError.uninitialized)
            return
        }
        
        let localUrl = cachesDirectory.appendingPathComponent(recordName)
        
        if let data = try? Data(contentsOf: localUrl) {
            completionHandler(data, nil)
        } else {
            database.fetch(withRecordID: .init(recordName: recordName)) { record, error in
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
        
        if #available(iOS 15.0, *) {
            database.fetch(withQuery: query, inZoneWith: .default, desiredKeys: desiredKeys, resultsLimit: resultsLimit) { result in
                switch result {
                case .success(let value):
                    for item in value.matchResults {
                        switch item.1 {
                        case .success(let record):
                            success(record)
                        case .failure(let error):
                            failure(error)
                        }
                    }
                    break
                case .failure(let error):
                    failure(error)
                }
            }
        } else {
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
}
