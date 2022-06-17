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
    func saveCKToolConfiguration(_ config: CKToolConfiguration) throws {
        try config.save(to: database()!)
    }
    
    func loadCKToolConfiguration() -> CKToolConfiguration {
        let result = (try? CKToolConfiguration.query(nil, from: database()!)) ?? []
        if let config = result.first {
            return config
        } else {
            return .init(containerId: "", developmentCKAPIToken: "", developmentCKWebAuthToken: "", productionCKAPIToken: "", productionCKWebAuthToken: "")
        }
    }
}

struct CKToolConfiguration: SQLiteRecord {
    static let table: Table = .init("CKToolConfiguration")
    static let idExpression: Expression<String> = .init("id")
    static let containerIdExpression: Expression<String> = .init("containerId")
    static let developmentCKAPITokenExpression: Expression<String> = .init("developmentCKAPIToken")
    static let developmentCKWebAuthTokenExpression: Expression<String> = .init("developmentCKWebAuthToken")
    static let productionCKAPITokenExpression: Expression<String> = .init("productionCKAPIToken")
    static let productionCKWebAuthTokenExpression: Expression<String> = .init("productionCKWebAuthToken")
    
    let id = "CKToolConfiguration"
    let containerId: String
    let developmentCKAPIToken: String
    let developmentCKWebAuthToken: String
    let productionCKAPIToken: String
    let productionCKWebAuthToken: String
    
    init(containerId: String, developmentCKAPIToken: String, developmentCKWebAuthToken: String, productionCKAPIToken: String, productionCKWebAuthToken: String) {
        self.containerId = containerId
        self.developmentCKAPIToken = developmentCKAPIToken
        self.developmentCKWebAuthToken = developmentCKWebAuthToken
        self.productionCKAPIToken = productionCKAPIToken
        self.productionCKWebAuthToken = productionCKWebAuthToken
    }
    
    static func create(to db: Connection) throws {
        try db.run(
            table.create(temporary: false, ifNotExists: true, withoutRowid: false, block: { builder in
                builder.column(idExpression, primaryKey: true)
                builder.column(containerIdExpression)
                builder.column(developmentCKAPITokenExpression)
                builder.column(developmentCKWebAuthTokenExpression)
                builder.column(productionCKAPITokenExpression)
                builder.column(productionCKWebAuthTokenExpression)
            })
        )
    }
    
    static func query(_ predicate: Expression<Bool>?, from db: Connection) throws -> [CKToolConfiguration] {
        let query = predicate == nil ? table : table.filter(predicate!)
        return try db.prepare(query).map { row in
            CKToolConfiguration(containerId: row[containerIdExpression], developmentCKAPIToken: row[developmentCKAPITokenExpression], developmentCKWebAuthToken: row[developmentCKWebAuthTokenExpression], productionCKAPIToken: row[productionCKAPITokenExpression], productionCKWebAuthToken: row[productionCKWebAuthTokenExpression])
        }
    }
    
    func save(to db: Connection) throws {
        let row = Self.table.filter(Self.idExpression == id)
        if try db.prepare(row).suffix(1).isEmpty {
            try db.run(
                Self.table.insert(
                    Self.idExpression <- id,
                    Self.containerIdExpression <- containerId,
                    Self.developmentCKAPITokenExpression <- developmentCKAPIToken,
                    Self.developmentCKWebAuthTokenExpression <- developmentCKWebAuthToken,
                    Self.productionCKAPITokenExpression <- productionCKAPIToken,
                    Self.productionCKWebAuthTokenExpression <- productionCKWebAuthToken
                )
            )
        } else {
            try db.run(
                row.update(
                    Self.containerIdExpression <- containerId,
                    Self.developmentCKAPITokenExpression <- developmentCKAPIToken,
                    Self.developmentCKWebAuthTokenExpression <- developmentCKWebAuthToken,
                    Self.productionCKAPITokenExpression <- productionCKAPIToken,
                    Self.productionCKWebAuthTokenExpression <- productionCKWebAuthToken
                )
            )
        }
    }
    
    func delete(to db: Connection) throws {
        try db.run(Self.table.filter(Self.idExpression == id).delete())
    }
}
