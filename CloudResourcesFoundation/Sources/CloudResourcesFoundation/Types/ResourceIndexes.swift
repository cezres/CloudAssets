//
//  File.swift
//  
//
//  Created by azusa on 2022/6/12.
//

import Foundation

public struct ResourceIndexesRecord: Codable, Equatable {
    public let recordName: String
    public let modifiedTimestamp: Double
    public let version: Int
    public let indexes: ResourceIndexes
    
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
