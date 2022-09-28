//
//  File.swift
//  
//
//  Created by azusa on 2022/6/12.
//

import Foundation

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
