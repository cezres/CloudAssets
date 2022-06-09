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
        let indexs: FileRecord
    }
    
    struct AssetsRecord: Codable {
        let recordName: String
        let name: String
        let version: Int
        let pathExtension: String
        let asset: FileRecord
    }
}

class CKToolJS: NSObject {
    private(set) var javaScriptString: String = ""
    
    weak var webView: WKWebView?
    
    var evaluateJavaScriptCompletionHandlers: [String: EvaluateJavaScriptCompletionHandler] = [:]
    var injectJs = DispatchGroup()
    var injected = false
    var session = Session()
    
    var configurationToken: String = ""
    
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
    
    func configureEnvironment(_ containerId: String, _ environment: String, _ userToken: String) {
        let js = JavaScriptMethod.configureEnvironment(containerId: containerId, environment: environment, userToken: userToken).createJavaScriptString(with: UUID().uuidString)
        webView?.evaluateJavaScript(js)
        configurationToken = CKToolConfiguration.init(containerId: containerId, environment: environment, userToken: userToken).token()
    }
        
    func deleteRecord(recordName: String) async throws {
        let result: String = try await evaluateJavaScript(method: .deleteRecord(recordName: recordName))
        debugPrint(result)
    }
    
    func queryAssetIndexsRecords() async throws -> [AssetIndexsRecord] {
        try await evaluateJavaScript(method: .queryAssetIndexsRecords(continuationToken: ""))
    }
    
    func queryResourceRecords() async throws -> [AssetsRecord] {
        try await evaluateJavaScript(method: .queryResourceRecords)
    }
    
    func createAssetsRecord(name: String, version: Int, asset: URL) async throws -> AssetsRecord {
        let attributes = try FileManager.default.attributesOfItem(atPath: asset.path)
        
        guard let size = attributes[.size] as? Int else {
            throw NSError(domain: "Invalid file size", code: -1)
        }
        debugPrint(size)
        
        let uploadUrlString: String = try await evaluateJavaScript(method: .createAssetUploadUrl(recordType: "Assets", fieldName: "asset", size: size))
        
        guard let uploadUrl = URL(string: uploadUrlString) else {
            throw NSError(domain: "Invalid uploadUrl: \(uploadUrlString)", code: -1)
        }
        
        let uploadResult = try await upload(uploadUrl, file: asset).singleFile
        
        let recordName = UUID().uuidString
        let result: AssetsRecord = try await evaluateJavaScript(method: .createResourceRecord(recordName: recordName, name: name, version: version, pathExtension: asset.pathExtension.lowercased(), fileChecksum: uploadResult.fileChecksum, receipt: uploadResult.receipt, size: size))
        return result
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
