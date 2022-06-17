//
//  CKToolJS.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/2.
//

import Foundation
import JavaScriptCore
import WebKit
import Alamofire

extension CKToolJS {
    struct FileRecord: Codable {
        let downloadUrl: String
        let fileChecksum: String
        let size: Int
    }
    
    struct AssetIndexsRecord: Codable {
        let recordName: String
        let version: Int
        let indexes: FileRecord
    }
    
    struct AssetsRecord: Codable {
        let recordName: String
        let name: String
        let version: Int
        let pathExtension: String
        let asset: FileRecord
    }
    
    struct ResourceIndexRecord: Codable {
        let recordName: String
        let version: Int
        let indexes: FileRecord
    }
}

class CKToolJS: NSObject {
    private(set) var javaScriptString: String = ""
    
    weak var webView: WKWebView?
    
    var evaluateJavaScriptCompletionHandlers: [String: EvaluateJavaScriptCompletionHandler] = [:]
    var injectJs = DispatchGroup()
    var injected = false
    var session = Session()
    
    let token = ""
    
    override init() {
        super.init()
        if let url = Bundle.main.url(forResource: "main", withExtension: "js"), let js = try? String(contentsOf: url) {
            javaScriptString = js
        } else {
            fatalError()
        }
        self.injectJs.enter()
    }
    
    func configureEnvironment(_ containerId: String, environment: String, ckAPIToken: String, ckWebAuthToken: String) {
        let js = JavaScriptMethod.configureEnvironment(
            containerId: containerId,
            environment: environment,
            ckAPIToken: ckAPIToken,
            ckWebAuthToken: ckWebAuthToken
        ).createJavaScriptString(with: UUID().uuidString)
        webView?.evaluateJavaScript(js)
    }
        
    func deleteRecord(recordName: String) async throws {
        let result: String = try await evaluateJavaScript(method: .deleteRecord(recordName: recordName))
        debugPrint(result)
    }
    
    func queryResourceIndexRecords() async throws -> [AssetIndexsRecord] {
        try await evaluateJavaScript(method: .queryResourceIndexRecords)
    }
    
    func queryResourceRecords() async throws -> [AssetsRecord] {
        try await evaluateJavaScript(method: .queryResourceRecords)
    }
    
    func createAssetsRecord(recordName: String, name: String, version: Int, pathExtension: String, asset: Data) async throws -> AssetsRecord {
//        let attributes = try FileManager.default.attributesOfItem(atPath: asset.path)
//
//        guard let size = attributes[.size] as? Int else {
//            throw NSError(domain: "Invalid file size", code: -1)
//        }
//        debugPrint(size)
        let size = asset.count
        
        let uploadUrlString: String = try await evaluateJavaScript(method: .createAssetUploadUrl(recordType: "Resource", fieldName: "asset", size: size))
        
        guard let uploadUrl = URL(string: uploadUrlString) else {
            throw NSError(domain: "Invalid uploadUrl: \(uploadUrlString)", code: -1)
        }
//        let uploadResult = try await upload(uploadUrl, file: asset).singleFile
        let uploadResult = try await upload(uploadUrl, data: asset).singleFile
        
//        let recordName = UUID().uuidString
        let result: AssetsRecord = try await evaluateJavaScript(method: .createResourceRecord(recordName: recordName, name: name, version: version, pathExtension: pathExtension.lowercased(), fileChecksum: uploadResult.fileChecksum, receipt: uploadResult.receipt, size: size))
        return result
    }
    
    func createResourceIndexRecord(indexes: ResourceIndexes) async throws -> ResourceIndexRecord {
        let data = try JSONEncoder().encode(indexes.indexes)
        let size = data.count
        
        print("Create upload url")
        let uploadUrlString: String = try await evaluateJavaScript(method: .createAssetUploadUrl(recordType: "ResourceIndexes", fieldName: "indexes", size: size))
        
        guard let uploadUrl = URL(string: uploadUrlString) else {
            throw NSError(domain: "Invalid uploadUrl: \(uploadUrlString)", code: -1)
        }
        print("Upload file")
        let uploadResult = try await upload(uploadUrl, data: data).singleFile

        print("Create record")
        let recordName = indexes.id.isEmpty ? "\(indexes.version)_resource_indexes" : indexes.id
        let result: ResourceIndexRecord = try await evaluateJavaScript(method: .createResourceIndexRecord(recordName: recordName, version: indexes.version, fileChecksum: uploadResult.fileChecksum, receipt: uploadResult.receipt, size: size))
        return result
    }
    
    func updateResourceIndexRecord(indexes: ResourceIndexes) async throws -> ResourceIndexRecord {
        let data = try JSONEncoder().encode(indexes.indexes)
        let size = data.count
        
        print("Create upload url")
        let uploadUrlString: String = try await evaluateJavaScript(method: .createAssetUploadUrl(recordType: "ResourceIndex", fieldName: "indexes", size: size))
        
        guard let uploadUrl = URL(string: uploadUrlString) else {
            throw NSError(domain: "Invalid uploadUrl: \(uploadUrlString)", code: -1)
        }
        print("Upload file")
        let uploadResult = try await upload(uploadUrl, data: data).singleFile

        print("Update record")
        let result: ResourceIndexRecord = try await evaluateJavaScript(method: .updateResourceIndexRecord(indexes.id, indexes.version, uploadResult.fileChecksum, uploadResult.receipt, size))
        return result
    }
    
    func searchResourceIndexRecord(id: String) async throws -> ResourceIndexRecord {
        try await evaluateJavaScript(method: .searchResourceIndexRecord(id))
    }
    
    func test() {
//        if
//            let parcelRequire = context.objectForKeyedSubscript("parcelRequire"),
//            let focm = parcelRequire.call(withArguments: ["Focm"])
//        {
//            if let azusa = focm.objectForKeyedSubscript("azusa"), let result = azusa.call(withArguments: ["azusa"]) {
//                print(result)
//            }
//            if let fetchRecord = focm.objectForKeyedSubscript("fetchRecord"), let result = fetchRecord.call(withArguments: ["819289739"]) {
//                print(result)
//            }
//            if
//                let queryRecords = focm.objectForKeyedSubscript("queryRecords"),
//                let result = queryRecords.call(withArguments: [])
//            {
//                print(result)
//            }
//        }
    }
}
