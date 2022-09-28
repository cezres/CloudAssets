//
//  CloudDatabase.swift
//  CloudResourcesManager
//
//  Created by 翟泉 on 2022/8/25.
//

import Foundation
import CloudKitWebServices

class CloudDatabase {
    var development: CloudKitWebServices
    var production: CloudKitWebServices
    
    init() {
        development = .init(configuration: .init(container: "", environment: "", database: "", serverKeyID: "", serverKey: ""))
        production = .init(configuration: .init(container: "", environment: "", database: "", serverKeyID: "", serverKey: ""))
    }
    
    func configureDevelopment(container: String, serverKeyID: String, serverKey: String) {
        development = .init(configuration: .init(container: container, environment: "development", database: "public", serverKeyID: serverKeyID, serverKey: serverKey))
    }
    
    func configureProduction(container: String, serverKeyID: String, serverKey: String) {
        production = .init(configuration: .init(container: container, environment: "production", database: "public", serverKeyID: serverKeyID, serverKey: serverKey))
    }
    
    func configure(_ configuration: ConfigurationState) {
        development = .init(configuration: .init(container: configuration.containerId, environment: "development", database: "public", serverKeyID: configuration.developmentServerKeyID, serverKey: configuration.developmentServerKey))
        production = .init(configuration: .init(container: configuration.containerId, environment: "production", database: "public", serverKeyID: configuration.productionServerKeyID, serverKey: configuration.productionServerKey))
    }
}
