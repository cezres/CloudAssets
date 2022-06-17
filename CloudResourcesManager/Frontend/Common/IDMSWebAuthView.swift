//
//  IDMSWebAuthView.swift
//  CloudResourcesManager
//
//  Created by azusa on 2022/6/14.
//

import SwiftUI
import WebKit

struct IDMSWebAuthView: View {
    @State var url: URL
    let callback: (_ ckWebAuthToken: String) -> Void
    
    var body: some View {
        ZStack {
            WebView(url: url, callback: callback)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        callback("")
                    } label: {
                        Text("Cancel")
                            .foregroundColor(.black)
                    }
                    .padding(30)
                }
                Spacer()
            }
        }
        .frame(width: 500, height: 400)
    }
    
}

extension IDMSWebAuthView {
    struct WebView: NSViewRepresentable {
        @State var url: URL
        let callback: (_ ckWebAuthToken: String) -> Void
        
        func makeNSView(context: Context) -> WKWebView {
            let nsView = WKWebView(frame: .init(x: 0, y: 0, width: 200, height: 200), configuration: .init())
            nsView.navigationDelegate = context.coordinator
            nsView.uiDelegate = context.coordinator
            nsView.configuration.userContentController.add(context.coordinator, name: "bridge")
            nsView.addObserver(context.coordinator, forKeyPath: "title", options: .new, context: nil)
            return nsView
        }
        
        func updateNSView(_ nsView: WKWebView, context: Context) {
            nsView.load(.init(url: url))
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(callback: callback)
        }
        
        typealias NSViewType = WKWebView
        
        class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
            
            let callback: (_ ckWebAuthToken: String) -> Void
            
            init(callback: @escaping (_ ckWebAuthToken: String) -> Void) {
                self.callback = callback
                super.init()
            }
            
            override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
                guard keyPath == "title" else {
                    return
                }
                guard let webView = object as? WKWebView else {
                    return
                }
                guard let title = webView.title else {
                    return
                }
                print(title)
                guard title.hasPrefix("Signing In") else {
                    return
                }
                print("注入JS重写postMessage函数")
                
                webView.evaluateJavaScript("""
                function __postMessage(v) {
                    console.log(v);
                    console.log("azusannzz");
                    webkit.messageHandlers.bridge.postMessage(v);
                }
                window.opener = {
                    "postMessage": __postMessage
                }
                const azusa_nn = 10086
                """)
                
                webView.evaluateJavaScript("azusa_nn") { value, error in
                    if let value = value {
                        print(value)
                    }
                    if let error = error {
                        print(error)
                    }
                }
            }
                        
            func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
                print(message.body)
                
                if let body = message.body as? [String: Any], let ckSession = body["ckSession"] as? String {
                    callback(ckSession)
                } else {
                    callback("")
                }
            }
        }
    }

}
