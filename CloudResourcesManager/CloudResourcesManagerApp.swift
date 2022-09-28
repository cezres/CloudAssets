//
//  CloudResourcesManagerApp.swift
//  CloudResourcesManager
//
//  Created by azusa on 2022/6/9.
//

import SwiftUI

@main
struct CloudResourcesManagerApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: .init(
                initialState: .init(),
                reducer: mainReducer,
                environment: .init(
                    cloudDatabase: .init(),
                    localDatabase: try! .init(.uri(DownloadsDirectory.appendingPathExtension("cloud_resouces.db").path()))
                )
            ))
        }
        .windowToolbarStyle(UnifiedWindowToolbarStyle(showsTitle: true))
    }
}
