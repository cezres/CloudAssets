//
//  Asset.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/9.
//

import Foundation
import SQLite

struct Asset: Equatable {
    let id: String
    let data: Data
}

extension Asset: SQLiteRecord {
    static let table: Table = .init("Asset")
    static let idExpression: Expression<String> = .init("id")
    static let dataExpression: Expression<Data> = .init("data")
    
    static func create(to db: Connection) throws {
        try db.run(
            table.create(temporary: false, ifNotExists: true, withoutRowid: false, block: { builder in
                builder.column(idExpression, primaryKey: true)
                builder.column(dataExpression)
            })
        )
    }
    
    static func query(_ predicate: Expression<Bool>?, from db: Connection) throws -> [Asset] {
        let query = predicate == nil ? table : table.filter(predicate!)
        return try db.prepare(query).map { row in
            Asset(id: row[idExpression], data: row[dataExpression])
        }
    }
    
    func save(to db: Connection) throws {
        let row = Self.table.filter(Self.idExpression == id)
        if try db.prepare(row).suffix(1).isEmpty {
            try db.run(
                Self.table.insert(
                    Self.idExpression <- id,
                    Self.dataExpression <- data
                )
            )
        } else {
            try db.run(
                row.update(
                    Self.dataExpression <- data
                )
            )
        }
    }
    
    func delete(to db: Connection) throws {
        try db.run(Self.table.filter(Self.idExpression == id).delete())
    }
}
