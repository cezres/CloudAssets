//
//  File.swift
//  
//
//  Created by azusa on 2022/6/12.
//

import Foundation

public struct ResourceRecord: Codable {
    public let recordName: String
    public let modifiedTimestamp: Double
    public let name: String
    public let version: Int
    public let pathExtension: String
    public let asset: AssetRecord
}
