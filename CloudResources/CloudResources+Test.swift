//
//  CloudAssets+Test.swift
//  CloudResources
//
//  Created by azusa on 2022/6/12.
//

import Foundation
import CloudKit
//import CloudResourcesFoundation

public extension CloudResources {
    func test() {
//        uploadAssets(name: "azusa", version: 100, url: .init(fileURLWithPath: "/Users/azusa/Pictures/ae8b83d9598534fa43f791a5ac688fecf0253009.jpg"))
//        uploadAssets(name: "azusa", version: 200, url: .init(fileURLWithPath: "/Users/azusa/Pictures/34cea126d0283d4d915fd08661412a9ee2d1452d.jpg"))
        
//        uploadAssetIndexs(
//            version: 11215,
//            indexs: .init(
//                version: 11215,
//                datas: [
//                    "azusa": "7251DAB2-9DC3-40B5-BD68-8706F60E36C9"
//                ],
//                images: [
//                    :
//                ]
//            )
//        )
//        uploadAssetIndexs(
//            version: 11214,
//            indexs: .init(
//                version: 11214,
//                datas: [
//                    "azusa": "83D3C9E3-6CEA-4637-A2C3-D29B223EAAD7"
//                ],
//                images: [
//                    :
//                ]
//            )
//        )
    }
}

extension CloudResources {
    func uploadAssetIndexs(version: Int, indexs: ResourceIndexes) {
        let recordName = "asset_indexs_\(version)"
        let url = cachesDirectory.appendingPathComponent(recordName)
        do {
            let data = try JSONEncoder().encode(indexs)
            try data.write(to: url)
        } catch {
            debugPrint(error)
            return
        }
        
        let record = CKRecord(recordType: "AssetIndexs", recordID: .init(recordName: recordName))
        record["version"] = version
        record["indexs"] = CKAsset(fileURL: url)
        
        container.publicCloudDatabase.save(record) { record, error in
            if let record = record {
                print(record)
            }
            if let error = error {
                print(error)
            }
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    func uploadAssets(name: String, version: Int, url: URL) {
        let record = CKRecord(recordType: "Assets", recordID: .init(recordName: UUID().uuidString))
        record["name"] = name
        record["version"] = version
        record["asset"] = CKAsset(fileURL: url)
        container.publicCloudDatabase.save(record) { record, error in
            if let record = record {
                print(record)
            }
            if let error = error {
                print(error)
            }
        }
    }
    
    func queryAssets() {
        let date = NSDate()
        
//        let query = CKQuery(recordType: "Assets", predicate: .init(format: "version <= 11215"))
        let query = CKQuery(recordType: "Assets", predicate: .init(format: "modificationDate <= %@", date))
//        let query = CKQuery(recordType: "Assets", predicate: .init(format: "TRUEPREDICATE"))
        query.sortDescriptors = [
//            .init(key: "version", ascending: false)
            .init(key: "modificationDate", ascending: true)
        ]
//        creationDate
//        modificationDate
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1
        operation.desiredKeys = [
            "name", "version"
        ]
        operation.queryCompletionBlock = { (cursor, error) in
            if let cursor = cursor {
                print(cursor)
            }
        }
        operation.recordFetchedBlock = { record in
            print(record)
            print(record.modificationDate!)
        }
        self.container.publicCloudDatabase.add(operation)
    }
}
