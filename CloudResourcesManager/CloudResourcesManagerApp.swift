//
//  CloudResourcesManagerApp.swift
//  CloudResourcesManager
//
//  Created by azusa on 2022/6/9.
//

import SwiftUI

@main
struct CloudResourcesManagerApp: App {
    let cktool = CKToolJS()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                __WebView(cktool: cktool)
                    .opacity(0)
                    .frame(width: 10, height: 10)
                
                ContentView(store: .init(
                    initialState: .init(indexes: []),
                    reducer: mainReducer,
                    environment: .init(cktool: cktool, database: .default)
                ))
            }
        }
        .windowToolbarStyle(UnifiedWindowToolbarStyle(showsTitle: true))
    }
}
