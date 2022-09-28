//
//  Database.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/6.
//

import Foundation
import SQLite
import SQLiteExt

let DownloadsDirectory = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0], isDirectory: true)

class LocalDatabase {
    public static let `default` = LocalDatabase(directory: DownloadsDirectory.appendingPathComponent("CloudResources", isDirectory: true))
    public static let inMemory = LocalDatabase(location: .inMemory)
    public static let temporary = LocalDatabase(location: .temporary)
    
    private var db: Connection?
    private let location: Connection.Location
    
    private init(location: Connection.Location) {
        self.location = location
        db = connection()
    }
    
    private convenience init(directory: URL) {
        do {
            let path = directory.appendingPathComponent("CloudResources.db").path
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false, attributes: nil)
            }
            self.init(location: .uri(path))
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func connection() -> Connection? {
        guard db == nil else {
            return db
        }
        
        do {
            db = try Connection(location, readonly: false)
        } catch {
            debugPrint(error)
        }
        return db
    }
}

extension Array where Element: SQLiteTable {
    func save(to db: Connection) throws {
        for item in self {
            try db.insert(item)
        }
    }
}
