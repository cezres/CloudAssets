//
//  CKToolConfiguration.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/9.
//

import Foundation
import CryptoKit
import SQLite

extension Database {
    func saveCKToolConfiguration(_ containerId: String, _ environment: String, _ userToken: String) throws {
        try CKToolConfiguration(
            containerId: containerId,
            environment: environment,
            userToken: userToken
        ).save(to: database()!)
    }
    
    func loadCKToolConfiguration() -> (containerId: String, environment: String, userToken: String) {
        let result = (try? CKToolConfiguration.query(nil, from: database()!)) ?? []
        if let config = result.first {
            return (config.containerId, config.environment, config.userToken)
        } else {
            return ("", ConfigurationState.Environment.development.rawValue, "")
        }
    }
}

struct CKToolConfiguration: SQLiteRecord {
    static let table: Table = .init("CKToolConfiguration")
    static let idExpression: Expression<String> = .init("id")
    static let containerIdExpression: Expression<String> = .init("containerId")
    static let environmentExpression: Expression<String> = .init("environment")
    static let userTokenExpression: Expression<String> = .init("userToken")
    
    let id = "CKToolConfiguration"
    let containerId: String
    let environment: String
    let userToken: String
    
    func token() -> String {
        var md5 = Insecure.MD5()
        md5.update(data: containerId.data(using: .utf8)!)
        md5.update(data: environment.data(using: .utf8)!)
        md5.update(data: userToken.data(using: .utf8)!)
        return Data(md5.finalize()).reduce("", { $0 + String(format: "%02x", $1) })
    }
    
    static func create(to db: Connection) throws {
        try db.run(
            table.create(temporary: false, ifNotExists: true, withoutRowid: false, block: { builder in
                builder.column(idExpression, primaryKey: true)
                builder.column(containerIdExpression)
                builder.column(environmentExpression)
                builder.column(userTokenExpression)
            })
        )
    }
    
    static func query(_ predicate: Expression<Bool>?, from db: Connection) throws -> [CKToolConfiguration] {
        let query = predicate == nil ? table : table.filter(predicate!)
        return try db.prepare(query).map { row in
            CKToolConfiguration(
                containerId: row[containerIdExpression],
                environment: row[environmentExpression],
                userToken: row[userTokenExpression]
            )
        }
    }
    
    func save(to db: Connection) throws {
        let row = Self.table.filter(Self.idExpression == id)
        if try db.prepare(row).suffix(1).isEmpty {
            try db.run(
                Self.table.insert(
                    Self.idExpression <- id,
                    Self.containerIdExpression <- containerId,
                    Self.environmentExpression <- environment,
                    Self.userTokenExpression <- userToken
                )
            )
        } else {
            try db.run(
                row.update(
                    Self.containerIdExpression <- containerId,
                    Self.environmentExpression <- environment,
                    Self.userTokenExpression <- userToken
                )
            )
        }
    }
    
    func delete(to db: Connection) throws {
        try db.run(Self.table.filter(Self.idExpression == id).delete())
    }
}
