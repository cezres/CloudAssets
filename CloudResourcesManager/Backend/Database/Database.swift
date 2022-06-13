//
//  Database.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/6.
//

import Foundation
import SQLite

let DownloadsDirectory = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0], isDirectory: true)

class Database {
    public static let `default` = Database(directory: DownloadsDirectory.appendingPathComponent("CloudResources", isDirectory: true))
    public static let inMemory = Database(location: .inMemory)
    public static let temporary = Database(location: .temporary)
    
    private var db: Connection?
    private let location: Connection.Location
    
    private init(location: Connection.Location) {
        self.location = location
        db = database()
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
    
    func database() -> Connection? {
        guard db == nil else {
            return db
        }
        
        do {
            db = try Connection(location, readonly: false)
            
            try Resource.create(to: db!)
            try CKToolConfiguration.create(to: db!)
            try Asset.create(to: db!)
            try ResourceIndexes.create(to: db!)
        } catch {
            debugPrint(error)
        }
        return db
    }
}

extension Array where Element: SQLiteRecord {
    func save(to db: Connection) throws {
        for item in self {
            try item.save(to: db)
        }
    }
}
