//
//  SQLiteRecord.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/9.
//

import Foundation
import SQLite

protocol SQLiteRecord {
    static var table: Table { get }
    
    static func create(to db: Connection) throws
    
    static func query(_ predicate: Expression<Bool>?, from db: Connection) throws -> [Self]
    
    func save(to db: Connection) throws
    
    func delete(to db: Connection) throws
}

extension Database {
    func save<T>(_ record: T) throws where T: SQLiteRecord {
        guard let db = database() else {
            throw NSError(domain: "database not initialized", code: -1)
        }
        try record.save(to: db)
    }
    
    func query<T>() throws -> [T] where T: SQLiteRecord {
        guard let db = database() else {
            throw NSError(domain: "database not initialized", code: -1)
        }
        return try T.query(nil, from: db)
    }
    
//    func delete<T>(_ id: String, type: T.Type) throws where T: SQLiteRecord {
//
//    }
}
