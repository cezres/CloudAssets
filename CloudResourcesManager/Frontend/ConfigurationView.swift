//
//  ConfigurationView.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/8.
//

import SwiftUI
import ComposableArchitecture

struct ConfigurationView: View {
    let store: Store<ConfigurationState, ConfigurationAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .leading) {
                Text("Configuration")
                    .font(.title)
                    .padding(.bottom, 16)
                    .padding(.top, 32)

                Text("Container Id")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Container Id", text: viewStore.binding(get: \.containerId, send: ConfigurationAction.setContainerId))
                    .padding(.bottom, 16)

                VStack(alignment: .leading) {
                    Text("Development")
                        .font(.title2)
                        .padding(.bottom, 8)
                    Text("ServerKey ID")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("ServerKey ID", text: viewStore.binding(get: \.developmentServerKeyID, send: ConfigurationAction.setDevelopmentServerKeyID))
                    Text("ServerKey")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("ServerKey", text: viewStore.binding(get: \.developmentServerKey, send: ConfigurationAction.setDevelopmentServerKey))
                }
                .padding(.bottom, 16)

                VStack(alignment: .leading) {
                    Text("Production")
                        .font(.title2)
                        .padding(.bottom, 8)
                    Text("ServerKey ID")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("ServerKey ID", text: viewStore.binding(get: \.productionServerKeyID, send: ConfigurationAction.setProductionServerKeyID))
                    Text("ServerKey")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("ServerKey", text: viewStore.binding(get: \.productionServerKey, send: ConfigurationAction.setProductionServerKey))
                }
                .padding(.bottom, 16)
               
                Button {
                    viewStore.send(.update)
                } label: {
                    Text("Save")
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(viewStore.isAbleToUpdate ? .blue : .gray)
                }
                .buttonStyle(.borderless)
                .cornerRadius(8)
                
                Spacer()
            }
            .padding(.horizontal, 30)
        }
    }
}
