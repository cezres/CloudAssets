//
//  Thumbnail.swift
//  CloudResourcesManager
//
//  Created by 翟泉 on 2022/8/25.
//

import Foundation
import SQLiteExt

struct Thumbnail: SQLiteTable, SQLiteTablePrimaryKey {
    
    static var primary: SQLiteFild<Thumbnail, String> = .init(identifier: "id", keyPath: \.id)
    
    static var fields: [AnySQLiteField<Thumbnail>] = [
        .init(identifier: "data", keyPath: \.data)
    ]
    
    var id: String = ""
    var data: Data = .init()
}
