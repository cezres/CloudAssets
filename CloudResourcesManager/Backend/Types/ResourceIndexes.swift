//
//  ResourceIndexes.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/9.
//

import Foundation
import SQLite

struct ResourceIndexes: Equatable, Identifiable {
    let id: String
    let version: Int
    var indexes: [ResourceName: Record]
    var checksum: String
    
    typealias ResourceName = String
    
    struct Record: Equatable, Codable {
        let id: String
    }
}

extension ResourceIndexes: SQLiteRecord {
    static let table: Table = .init("ResourceIndex")
    static let idExpression: Expression<String> = .init("id")
    static let versionExpression: Expression<Int> = .init("version")
    static let indexesExpression: Expression<Data> = .init("indexes")
    static let checksumExpression: Expression<String> = .init("checksum")
    
    static func create(to db: Connection) throws {
        try db.run(
            table.create(temporary: false, ifNotExists: true, withoutRowid: false, block: { builder in
                builder.column(idExpression, primaryKey: true)
                builder.column(versionExpression)
                builder.column(indexesExpression)
                builder.column(checksumExpression)
            })
        )
    }
    
    static func query(_ predicate: Expression<Bool>?, from db: Connection) throws -> [ResourceIndexes] {
        let query = predicate == nil ? table : table.filter(predicate!)
        return try db.prepare(query).map { row in
            let data = row[indexesExpression]
            let indexes = try JSONDecoder().decode([ResourceName: Record].self, from: data)
            return ResourceIndexes(id: row[idExpression], version: row[versionExpression], indexes: indexes, checksum: row[checksumExpression])
        }
    }
    
    func save(to db: Connection) throws {
        let row = Self.table.filter(Self.idExpression == id)
        let indexesData = try JSONEncoder().encode(indexes)
        if try db.prepare(row).suffix(1).isEmpty {
            try db.run(
                Self.table.insert(
                    Self.idExpression <- id,
                    Self.versionExpression <- version,
                    Self.indexesExpression <- indexesData,
                    Self.checksumExpression <- checksum
                )
            )
        } else {
            try db.run(
                row.update(
                    Self.versionExpression <- version,
                    Self.indexesExpression <- indexesData,
                    Self.checksumExpression <- checksum
                )
            )
        }
    }
    
    func delete(to db: Connection) throws {
        try db.run(Self.table.filter(Self.idExpression == id).delete())
    }
}
