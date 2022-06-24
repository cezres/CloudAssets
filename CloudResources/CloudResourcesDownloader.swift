//
//  CloudResourcesDownloader.swift
//  CloudResources
//
//  Created by azusa on 2022/6/16.
//

import Foundation
import CloudKit

protocol CloudResourcesDownloader {
    func fetch(_ recordName: String, completionHandler: @escaping (_ url: URL?, _ error: Error?) -> Void)
}

protocol CloudResourcesCaches {
    func save(id: String, url: URL)
    func load(id: String) -> URL?
}
