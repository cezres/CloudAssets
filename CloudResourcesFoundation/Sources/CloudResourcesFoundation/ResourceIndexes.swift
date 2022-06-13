//
//  File.swift
//  
//
//  Created by azusa on 2022/6/12.
//

import Foundation

public struct ResourceIndexesRecord: Codable {
    public let recordName: String
    public let modifiedTimestamp: Double
    
    public let version: Int
    public let indexes: AssetRecord
}

public typealias ResourceName = String

public struct ResourceIndex: Codable {
    public let id: String
}

public typealias ResourceIndexes = [ResourceName: ResourceIndex]
