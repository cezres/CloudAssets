//
//  CKToolJS+Upload.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/7.
//

import Foundation

extension CKToolJS {
    struct UploadResult: Codable {
        let singleFile: SingleFile
        
        struct SingleFile: Codable {
            let size: Int
            let fileChecksum: String
            let receipt: String
        }
    }
    
    func upload(_ url: URL, file: URL) async throws -> UploadResult {
        var result: UploadResult?
        var err: Error?
        
        let group = DispatchGroup()
        group.enter()
        session.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(file, withName: "file")
        }, to: url).responseData { response in
            if let data = response.data {
                print(String(data: data, encoding: .utf8) ?? "Null")
                do {
                    result = try JSONDecoder().decode(UploadResult.self, from: data)
                } catch {
                    err = error
                }
            } else if let error = response.error {
                print(error)
                err = error
            } else {
                print(response)
                err = NSError(domain: "upload fail", code: -1)
            }
            group.leave()
        }.resume()
        group.wait()
        
        if let err = err {
            throw err
        }
        return result!
    }

}
