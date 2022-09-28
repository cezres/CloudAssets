//
//  ResourceIndexes.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/9.
//

import Foundation
import SQLite
import SQLiteExt

public struct ResourceIndexesRecord: Codable, Equatable {
    public var recordName: String = ""
    public var modifiedTimestamp: Double = 0
    public var version: Int = 0
    public var indexes: ResourceIndexes = [:]
    
    public init(recordName: String, modifiedTimestamp: Double, version: Int, indexes: ResourceIndexes) {
        self.recordName = recordName
        self.modifiedTimestamp = modifiedTimestamp
        self.version = version
        self.indexes = indexes
    }
}

public typealias ResourceName = String

public struct ResourceIndex: Codable, Equatable {
    public let id: String
}

public typealias ResourceIndexes = [ResourceName: ResourceIndex]


extension ResourceIndexesRecord: Identifiable {
    public var id: String {
        recordName
    }
}

extension ResourceIndexesRecord: SQLiteTable, SQLiteTablePrimaryKey {
    public init() {
        
    }
    
    public static var primary: SQLiteFild<ResourceIndexesRecord, String> = .init(identifier: "recordName", keyPath: \.recordName)
    
    public static var fields: [AnySQLiteField<ResourceIndexesRecord>] = [
        .init(identifier: "version", keyPath: \.version),
        .init(identifier: "indexes", keyPath: \.__w_indexes),
        .init(identifier: "modifiedTimestamp", keyPath: \.modifiedTimestamp),
    ]
    
    private var __w_indexes: __W_Indexes {
        get {
            .init(indexes: indexes)
        }
        set {
            indexes = newValue.indexes
        }
    }
}

private struct __W_Indexes: Value, Codable {
    
    public var indexes: ResourceIndexes = [:]
    
    typealias Datatype = Blob
    
    static var declaredDatatype: String {
        Datatype.declaredDatatype
    }
    
    static func fromDatatypeValue(_ datatypeValue: Blob) -> __W_Indexes {
        do {
            return try JSONDecoder().decode(__W_Indexes.self, from: Data.fromDatatypeValue(datatypeValue))
        } catch {
            return .init()
        }
    }
    
    var datatypeValue: Blob {
        do {
            return try JSONEncoder().encode(self).datatypeValue
        } catch {
            return Data().datatypeValue
        }
    }
    
}
