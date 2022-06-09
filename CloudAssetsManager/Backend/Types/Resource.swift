//
//  Resource.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/6.
//

import Foundation
import SQLite

struct Resource: Equatable, Identifiable {
    let id: String
    let name: String
    let version: Int
    let pathExtension: String
    let checksum: String
    
    func data() -> Data? {
        searchAssetFromLocalDB()?.data
    }
    
    func hasLocalData(in db: Connection) -> Bool {
        let row = Asset.table.filter(Asset.idExpression == id)
        do {
            return !(try db.prepare(row).suffix(1).isEmpty)
        } catch {
            return false
        }
    }
    
    func searchAssetFromLocalDB() -> Asset? {
        try? Asset.query(Asset.idExpression == id, from: Database.default.database()!).first
    }
    
    func downloadAssetFromCloud() async throws -> Asset {
        return .init(id: "", data: .init())
    }
}

extension Resource: SQLiteRecord {
    static let table: Table = .init("Assets")
    static let idExpression: Expression<String> = .init("id")
    static let nameExpression: Expression<String> = .init("name")
    static let versionExpression: Expression<Int> = .init("version")
    static let pathExtensionExpression: Expression<String> = .init("pathExtension")
    static let checksumExpression: Expression<String> = .init("checksum")
    
    func delete(to db: Connection) throws {
        try db.run(Self.table.filter(Self.idExpression == id).delete())
    }
    
    func save(to db: Connection) throws {
        let row = Self.table.filter(Self.idExpression == id)
        if try db.prepare(row).suffix(1).isEmpty {
            try db.run(
                Self.table.insert(
                    Self.idExpression <- id,
                    Self.nameExpression <- name,
                    Self.versionExpression <- version,
                    Self.pathExtensionExpression <- pathExtension,
                    Self.checksumExpression <- checksum
                )
            )
        } else {
            try db.run(
                row.update(
                    Self.nameExpression <- name,
                    Self.versionExpression <- version,
                    Self.pathExtensionExpression <- pathExtension,
                    Self.checksumExpression <- checksum
                )
            )
        }
    }
    
    static func query(_ predicate: Expression<Bool>? = nil, from db: Connection) throws -> [Resource] {
        let query = predicate == nil ? table : table.filter(predicate!)
        return try db.prepare(query).map { row in
            Resource(
                id: row[idExpression],
                name: row[nameExpression],
                version: row[versionExpression],
                pathExtension: row[pathExtensionExpression],
                checksum: row[checksumExpression]
            )
        }
    }
    
    static func create(to db: Connection) throws {
        try db.run(
            table.create(temporary: false, ifNotExists: true, withoutRowid: false, block: { builder in
                builder.column(idExpression, primaryKey: true)
                builder.column(nameExpression)
                builder.column(versionExpression)
                builder.column(pathExtensionExpression)
                builder.column(checksumExpression)
            })
        )
    }
}

