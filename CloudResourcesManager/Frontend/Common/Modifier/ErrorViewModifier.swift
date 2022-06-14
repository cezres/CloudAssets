//
//  ErrorViewModifier.swift
//  CloudResourcesManager
//
//  Created by azusa on 2022/6/13.
//

import SwiftUI

struct ErrorViewModifier: ViewModifier {
    var error: Binding<String>
    
    func body(content: Content) -> some View {
        content.sheet(
            isPresented: .init(get: {
                return !error.wrappedValue.isEmpty
            }, set: { value in
                if !value {
                    error.wrappedValue = ""
                }
            })) {
                VStack {
                    Text(error.wrappedValue)
                        .padding(.bottom, 16)
                    Button("OK") {
                        error.wrappedValue = ""
                    }
                }
                .frame(maxWidth: 600)
                .padding(30)
            }
    }
}

extension View {
    func error(_ error: Binding<String>) -> some View {
        modifier(ErrorViewModifier(error: error))
    }
}

extension Error {
    func toString() -> String {
        return (self as NSError).domain
    }
}
