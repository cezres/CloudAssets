//
//  Asset.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/9.
//

import Foundation
import SQLiteExt

struct Asset: Equatable {
    var id: String = ""
    var data: Data = .init()
}

extension Asset: SQLiteTable, SQLiteTablePrimaryKey {
    
    static var primary: SQLiteFild<Asset, String> = .init(identifier: "id", keyPath: \.id)
    
    static var fields: [AnySQLiteField<Asset>] = [
        .init(identifier: "data", keyPath: \.data)
    ]
}
