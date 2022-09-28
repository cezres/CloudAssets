//
//  CloudResources+Configuration.swift
//  CloudResources
//
//  Created by 翟泉 on 2022/9/5.
//

import Foundation
import CloudKit

extension CloudResources {
    
    enum ConfigurationValueType: String, Codable {
        case string
        case strings
        case bool
        case unknown
    }
    
    enum ConfigurationValue: Codable {
        case string(String)
        case strings([String])
        case bool(Bool)
        case unknown
        
        init(from decoder: Decoder) throws {
            do {
                let container = try decoder.container(keyedBy: ConfigurationValue.CodingKeys.self)
                switch try container.decode(ConfigurationValueType.self, forKey: .type) {
                case .string:
                    self = .string(try container.decode(String.self, forKey: .value))
                case .strings:
                    self = .strings(try container.decode([String].self, forKey: .value))
                case .bool:
                    self = .bool(try container.decode(Bool.self, forKey: .value))
                case .unknown:
                    self = .unknown
                }
            } catch {
                debugPrint(error)
                self = .unknown
            }
        }
        
        enum CodingKeys: CodingKey {
            case value
            case type
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: ConfigurationValue.CodingKeys.self)
            switch self {
            case .string(let value):
                try container.encode(value, forKey: .value)
            case .strings(let value):
                try container.encode(value, forKey: .value)
            case .bool(let value):
                try container.encode(value, forKey: .value)
            case .unknown:
                break
            }
            try container.encode(valueType, forKey: .type)
        }
        
        var valueType: ConfigurationValueType {
            switch self {
            case .string:
                return .string
            case .strings:
                return .strings
            case .bool:
                return .bool
            case .unknown:
                return .unknown
            }
        }
        
        func value() -> Any? {
            switch self {
            case .string(let value):
                return value
            case .strings(let value):
                return value
            case .bool(let value):
                return value
            case .unknown:
                return nil
            }
        }
    }
    
    struct Configuration: Codable {
        let version: Int64
        let modifiedTimestamp: TimeInterval
        let items: [String: ConfigurationValue]
    }
    
//    @CloudConfigurationActor
    func loadConfiguration() {
        guard let database = container?.publicCloudDatabase, let version = version else {
            return
        }
        
        let localUrl = cachesDirectory.appendingPathComponent("configuration")
        if let result = try? JSONDecoder().decode(Configuration.self, from: .init(contentsOf: localUrl)) {
            configuration = result
        } else {
            configuration = .init(version: 0, modifiedTimestamp: 0, items: [:])
        }
        
        let query = CKQuery(recordType: "Configuration", predicate: .init(format: "version <= \(version)"))
        query.sortDescriptors = [
            .init(key: "version", ascending: false)
        ]
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1
        operation.desiredKeys = [
            "version"
        ]
        operation.recordFetchedBlock = { record in
            guard let version = record["version"] as? Int64, let timestamp = record.modificationDate?.timeIntervalSince1970 else {
                return
            }
            guard version > self.configuration.version || timestamp > self.configuration.modifiedTimestamp else {
                return
            }
            // load new record
            database.fetch(withRecordID: record.recordID) { record, error in
                guard let record = record, let asset = record["items"] as? CKAsset, let url = asset.fileURL else { return }
                do {
                    debugPrint(url.absoluteString)
                    let data = try Data(contentsOf: url)
                    let items = try JSONDecoder().decode([String: ConfigurationValue].self, from: data)
                    self.configuration = .init(version: version, modifiedTimestamp: timestamp, items: items)
                    try JSONEncoder().encode(self.configuration).write(to: localUrl)
                } catch {
                    debugPrint(error)
                }
            }
        }
        operation.queryCompletionBlock = { (cursor, error) in
        }
        database.add(operation)
    }
    
    func value<T>(forKey key: String) -> T? {
        configuration.items[key]?.value() as? T
    }
    public func string(forKey key: String) -> String? {
        value(forKey: key)
    }
    public func strings(forKey key: String) -> [String]? {
        value(forKey: key)
    }
    public func bool(forKey key: String) -> Bool {
        value(forKey: key) ?? false
    }
        
//    func resource(forKey key: String) async -> Data? {
//        if let task = await resourceTasks[key] {
//            return await task.value
//        } else {
//            let task = Task<Data?, Never> {
//                do {
//                    let url = try await self.fetchResourceURL(key)
//                    return try Data(contentsOf: url)
//                } catch {
//                    return nil
//                }
//            }
//            await setResourceTask(task, forKey: key)
//            return await task.value
//        }
//    }
//    func resource(forKey key: String) -> Data? {
//        return nil
//    }
    
    @CloudResourceActor func setResourceTask(_ task: Task<Data?, Never>, forKey key: String) async {
        resourceTasks[key] = task
    }
}
