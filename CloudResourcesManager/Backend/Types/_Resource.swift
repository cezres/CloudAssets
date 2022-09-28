//
//  Resource.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/6.
//

import Foundation
import SQLite
import SQLiteExt
import Cocoa

struct Resource: Equatable, Identifiable {
    var id: String = ""
    var name: String = ""
    var version: Int = 0
    var pathExtension: String = ""
    var fileChecksum: String = ""
    var modifiedTimestamp: TimeInterval = 0
    
    func data(_ db: Connection) -> Data? {
        searchAssetFromLocalDB(db)?.data
    }
    
    func thumbnail(_ db: Connection) async -> NSImage? {
        guard ["png"].contains(pathExtension.lowercased()) else {
            return nil
        }
        
        // Load thumbnail
        if let result: Thumbnail = try? db.find(primary: id) {
            return .init(data: result.data)
        } else if let asset: Asset = try? db.find(primary: id) {
            // Create thumbnail
            // TODO: Create thumbnail
            return NSImage(data: asset.data)
        }
        return nil
    }
    
    func hasLocalData(in db: Connection) -> Bool {
        let row = Table(Asset.tableName).filter(Asset.primary.expression() == id)
        do {
            return !(try db.prepare(row).suffix(1).isEmpty)
        } catch {
            return false
        }
    }
    
    func searchAssetFromLocalDB(_ db: Connection) -> Asset? {
        try? db.find(type: Asset.self, primary: id)
    }
    
    func downloadAssetFromCloud() async throws -> Asset {
        return .init(id: "", data: .init())
    }
}

extension Resource: SQLiteTable, SQLiteTablePrimaryKey {
    
    static var primary: SQLiteFild<Resource, String> = .init(identifier: "id", keyPath: \.id)
    
    static var fields: [AnySQLiteField<Resource>] = [
        .init(identifier: "name", keyPath: \.name),
        .init(identifier: "version", keyPath: \.version),
        .init(identifier: "pathExtension", keyPath: \.pathExtension),
        .init(identifier: "fileChecksum", keyPath: \.fileChecksum),
        .init(identifier: "modifiedTimestamp", keyPath: \.modifiedTimestamp)
    ]
}
