//
//  CKToolJS+WebView.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/7.
//

import Foundation
import WebKit

extension CKToolJS {
    enum JavaScriptMethod {
        case configureEnvironment(containerId: String, environment: String, userToken: String)
        case queryResourceIndexRecords
        case queryResourceRecords
        
        
        case createAssetUploadUrl(recordType: String, fieldName: String, size: Int)
        case createResourceRecord(recordName: String, name: String, version: Int, pathExtension: String, fileChecksum: String, receipt: String, size: Int)
        
        case createResourceIndexRecord(recordName: String, version: Int, fileChecksum: String, receipt: String, size: Int)
        case searchResourceIndexRecord(_ recordName: String)
        case updateResourceIndexRecord(_ recordName: String, _ version: Int, _ fileChecksum: String, _ receipt: String, _ size: Int)
        
        case deleteRecord(recordName: String)
        
        func createJavaScriptString(with callbackId: String) -> String {
            switch self {
            case .configureEnvironment(let containerId, let environment, let userToken):
                return """
                main.configureEnvironment("\(containerId)", "\(environment)", "\(userToken)")
                """
            case .queryResourceIndexRecords:
                return """
                main.queryResourceIndexRecords("\(callbackId)")
                """
            case .queryResourceRecords:
                return """
                main.queryResourceRecords("\(callbackId)")
                """
            case .createAssetUploadUrl(let recordType, let fieldName, let size):
                return """
                main.createAssetUploadUrl("\(callbackId)", "\(recordType)", "\(fieldName)", \(size))
                """
            case .createResourceRecord(let recordName, let name, let version, let pathExtension, let fileChecksum, let receipt, let size):
                return """
                main.createResourceRecord("\(callbackId)", "\(recordName)", "\(name)", \(version), "\(pathExtension)", "\(fileChecksum)", "\(receipt)", \(size))
                """
            case .createResourceIndexRecord(let recordName, let version, let fileChecksum, let receipt, let size):
                return """
                main.createResourceIndexesRecord("\(callbackId)", "\(recordName)", \(version), "\(fileChecksum)", "\(receipt)", \(size))
                """
            case .searchResourceIndexRecord(let recordName):
                return """
                main.searchResourceIndexesRecord("\(callbackId)", "\(recordName)")
                """
            case .updateResourceIndexRecord(let recordName, let version, let fileChecksum, let receipt, let size):
                return """
                main.updateResourceIndexesRecord("\(callbackId)", "\(recordName)", \(version), "\(fileChecksum)", "\(receipt)", \(size))
                """
            case .deleteRecord(let recordName):
                return """
                main.deleteRecord("\(callbackId)", "\(recordName)")
                """
            }
        }
    }
    
    func evaluateJavaScript<R: Codable>(method: JavaScriptMethod) async throws -> R {
        guard let webView = webView else { throw NSError(domain: "webView is nil", code: -1) }
        self.injectJs.wait()
        
        let id = UUID().uuidString
        var err: Error?
        var result: R?
        
        evaluateJavaScriptCompletionHandlers[id] = .init(success: { body in
            guard let data = body["data"] else {
                err = NSError(domain: "data is nil", code: -2)
                print(body)
                return
            }
            do {
                if let value = data as? R {
                    result = value
                } else {
                    let _data = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                    result = try JSONDecoder().decode(R.self, from: _data)
                }
            } catch {
                err = error
            }
        }, error: { error in
            err = NSError(domain: error, code: -1, userInfo: nil)
        })
        
        evaluateJavaScriptCompletionHandlers[id]?.group.enter()
        
        DispatchQueue.main.async {
            webView.evaluateJavaScript(method.createJavaScriptString(with: id))
        }
        
        _ = evaluateJavaScriptCompletionHandlers[id]?.group.wait(timeout: .now() + 20)
        
        if let result = result {
            return result
        } else if let err = err {
            throw err
        } else {
            throw NSError(domain: "[CKToolJS] unknown response", code: -1)
        }
    }
}

extension CKToolJS: WKScriptMessageHandler, WKNavigationDelegate {
    struct EvaluateJavaScriptCompletionHandler {
        let id = UUID().uuidString
        let group = DispatchGroup()
        let success: (_ body: [String: Any]) -> Void
        let error: (_ error: String) -> Void
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else {
            print(message.body)
            return
        }
        if
            let id = body["id"] as? String,
            let handler = evaluateJavaScriptCompletionHandlers.removeValue(forKey: id)
        {
            if let error = body["error"] as? String {
                print(body)
                handler.error(error)
            } else if let error = body["error"] as? [String: Any] {
                handler.error(error.description)
            } else {
                handler.success(body)
            }
            handler.group.leave()
        } else {
            print(body)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard !injected else {
            return
        }
        injected = true
        webView.evaluateJavaScript(javaScriptString) { result, error in
            if let result = result {
                print(result)
            }
            if let error = error {
                print(error)
            }
            let javaScriptString = """
            main.configureEnvironment("iCloud.im.bycoin.ios", "DEVELOPMENT", "\(self.token)")
            """
            webView.evaluateJavaScript(javaScriptString) { result, error in
                if let result = result {
                    print(result)
                }
                if let error = error {
                    print(error)
                }
                self.injectJs.leave()
            }
        }
    }
}
