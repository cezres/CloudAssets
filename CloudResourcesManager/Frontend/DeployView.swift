//
//  DeployView.swift
//  CloudResourcesManager
//
//  Created by azusa on 2022/6/13.
//

import SwiftUI

struct DeployView: View {
    var body: some View {
        VStack {
            Button {
                
            } label: {
                Text("Deploy Resources And Indexes Changes")
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.blue)
            }
            .buttonStyle(.borderless)
            .cornerRadius(8)
        }
    }
}

