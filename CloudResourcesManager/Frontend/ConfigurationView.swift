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
    
    @State var isPresented = false
    @State var url: String = ""
    @State var env: ConfigurationState.Environment = .development
        
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .leading) {
                Text("Configuration")
                    .font(.title)
                    .padding(.bottom, 16)
                
                Text("Container Id")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Container Id", text: viewStore.binding(get: \.containerId, send: ConfigurationAction.setContainerId))
                    .padding(.bottom, 16)
                
                VStack(alignment: .leading) {
                    Text("Development")
                        .font(.title2)
                        .padding(.bottom, 8)
                    Text("API Token")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("API Token", text: viewStore.binding(get: \.developmentCKAPIToken, send: ConfigurationAction.setDevelopmentCKAPIToken))
                    Text("Web Auth Token")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("Web Auth Token", text: viewStore.binding(get: \.developmentCKWebAuthToken, send: ConfigurationAction.setDevelopmentCKWebAuthToken))
                        .disabled(true)
                    signInWithApple(viewStore: viewStore, env: .development)
                        .padding(.bottom, 16)
                }
                
                VStack(alignment: .leading) {
                    Text("Production")
                        .font(.title2)
                        .padding(.bottom, 8)
                    Text("API Token")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("API Token", text: viewStore.binding(get: \.productionCKAPIToken, send: ConfigurationAction.setProductionCKAPIToken))
                    Text("Web Auth Token")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("Web Auth Token", text: viewStore.binding(get: \.productionCKWebAuthToken, send: ConfigurationAction.setProductionCKWebAuthToken))
                        .disabled(true)
                    signInWithApple(viewStore: viewStore, env: .production)
                        .padding(.bottom, 16)
                }
            }
            .loading(viewStore.binding(get: \.isLoading, send: ConfigurationAction.setLoading))
            .error(viewStore.binding(get: \.error, send: ConfigurationAction.setError))
            .padding(30)
            .sheet(isPresented: $isPresented) {
                if let url = URL(string: url) {
                    IDMSWebAuthView(url: url) { ckWebAuthToken in
                        debugPrint(ckWebAuthToken)
                        if env == .development {
                            viewStore.send(.setDevelopmentCKWebAuthToken(ckWebAuthToken))
                        } else {
                            viewStore.send(.setProductionCKWebAuthToken(ckWebAuthToken))
                        }
                        viewStore.send(.update)
                        isPresented = false
                    }
                }
            }
        }
    }
    
    func signInWithApple(viewStore: ViewStore<ConfigurationState, ConfigurationAction>, env: ConfigurationState.Environment) -> some View {
        Button {
            guard
                !viewStore.containerId.isEmpty
            else {
                return
            }
            if env == .development && viewStore.developmentCKAPIToken.isEmpty {
                return
            } else if env == .production && viewStore.productionCKAPIToken.isEmpty {
                return
            }
            let ckAPIToken = env == .development ? viewStore.developmentCKAPIToken : viewStore.productionCKAPIToken
            let ckWebAuthToken = env == .development ? viewStore.developmentCKWebAuthToken : viewStore.productionCKWebAuthToken
            
            viewStore.send(.update)
            viewStore.send(.setLoading(true))
            self.env = env
            Task {
                let result = await authenticateUser(containerId: viewStore.containerId, ckAPIToken: ckAPIToken, ckWebAuthToken: ckWebAuthToken, env: env)
                
                DispatchQueue.main.async {
                    viewStore.send(.setLoading(false))
                    
                    switch result {
                    case .userRecordName(_):
                        viewStore.send(.update)
                        viewStore.send(.setError("Does not require authorization"))
                    case .requestNeedsAuthorization(let redirectURL):
                        url = redirectURL
                        isPresented = true
                    case .error(let error):
                        viewStore.send(.setError(error?.toString() ?? ""))
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "applelogo")
                    .foregroundColor(Color.white)
                Text("Sign in with Apple")
                    .foregroundColor(Color.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.blue)
        }
        .buttonStyle(.borderless)
        .cornerRadius(8)
    }
    
    func environmentPicker() -> some View {
        WithViewStore(store) { viewStore in
//            Picker(selection: Binding<Int>.init {
//                viewStore.environment == .development ? 0 : 1
//            } set: { newValue in
//                viewStore.send(.setEnvironment(newValue == 0 ? .development : .production))
//            }) {
//                Text(ConfigurationState.Environment.development.rawValue).tag(0)
//                Text(ConfigurationState.Environment.production.rawValue).tag(1)
//            } label: {
//                Text("Environment")
//            }
//            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    enum AuthenticateUserResult {
        case requestNeedsAuthorization(_ redirectURL: String)
        case userRecordName(_ userRecordName: String)
        case error(_ error: Error?)
    }
    
    func authenticateUser(containerId: String, ckAPIToken: String, ckWebAuthToken: String, env: ConfigurationState.Environment) async -> AuthenticateUserResult {
        var string = "https://api.apple-cloudkit.com/database/1/\(containerId)/\(env.rawValue.lowercased())/public/users/current?ckAPIToken=\(ckAPIToken)"
//        if !ckWebAuthToken.isEmpty {
//            let ckWebAuthToken = ckWebAuthToken
//                .replacingOccurrences(of: "+", with: "%2B")
//                .replacingOccurrences(of: "/", with: "%2F")
//                .replacingOccurrences(of: "=", with: "%3D")
//            string += "&ckWebAuthToken=\(ckWebAuthToken)"
//        }
        
        struct RequestResult: Codable {
            let redirectURL: String?
            let userRecordName: String?
        }
        
        var result: RequestResult?
        var err: Error?
        let session = URLSession.shared
        let group = DispatchGroup()
        group.enter()
        session.dataTask(with: URL(string: string)!) { data, response, error in
            if let data = data {
                print(String(data: data, encoding: .utf8) ?? "")
                do {
                    result = try JSONDecoder().decode(RequestResult.self, from: data)
                } catch {
                    err = error
                }
            } else if let error = error {
                err = error
            } else {
                err = NSError(domain: "Null data", code: -1)
            }
            group.leave()
        }.resume()
        group.wait()
        
        if let result = result {
            if let redirectURL = result.redirectURL {
                return .requestNeedsAuthorization(redirectURL)
            } else if let userRecordName = result.userRecordName {
                return .userRecordName(userRecordName)
            } else {
                return .error(NSError(domain: "network exception error", code: -1))
            }
        } else {
            return .error(err)
        }
    }
}

