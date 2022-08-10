//
//  File.swift
//  
//
//  Created by azusa on 2022/6/12.
//

import Foundation

public struct AssetRecord: Codable {
    public let fileChecksum: String
    public let downloadUrl: String
    public let size: Int
}
