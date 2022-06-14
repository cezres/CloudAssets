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
    
    @State var env: Int = 0
    let datas: [ConfigurationState.Environment] = [.development, .production]
    
    init(store: Store<ConfigurationState, ConfigurationAction>) {
        self.store = store
    }
        
    var body: some View {
        WithViewStore(store) { viewStore in
            Form {
                Section {
                    TextField("Container Id", text: viewStore.binding(get: \.containerId, send: ConfigurationAction.setContainerId))
                    TextField("User Token", text: viewStore.binding(get: \.userToken, send: ConfigurationAction.setUserToken))
                    Picker(selection: Binding<Int>.init {
                        viewStore.environment == .development ? 0 : 1
                    } set: { newValue in
                        viewStore.send(.setEnvironment(newValue == 0 ? .development : .production))
                    }) {
                        Text(ConfigurationState.Environment.development.rawValue).tag(0)
                        Text(ConfigurationState.Environment.production.rawValue).tag(1)
                    } label: {
                        Text("Environment")
                    }
                    .pickerStyle(SegmentedPickerStyle())

                } header: {
                    Text("Configuration")
                        .font(.title)
                }
                
                Section {
                    Button {
                        if viewStore.isChanged {
                            viewStore.send(.update)
                        }
                    } label: {
                        Text("Update")
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(viewStore.isChanged ? .blue : .gray)
                    }
                    .buttonStyle(.borderless)
                    .cornerRadius(8)
                    .padding(.bottom, 30)
                }
                Spacer()
            }
            .error(viewStore.binding(get: \.error, send: ConfigurationAction.setError))
            .padding(30)
        }
        
    }
}

