//
//  LoadingModifier.swift
//  CloudResourcesManager
//
//  Created by azusa on 2022/6/13.
//

import SwiftUI
import SwiftUIX

struct LoadingViewModifier: ViewModifier {
    var isLoading: Binding<Bool>
    
    func body(content: Content) -> some View {
        content.sheet(isPresented: isLoading) {
            VStack {
                ActivityIndicator()
            }
            .frame(width: 100, height: 100, alignment: .center)
            .cornerRadius(12)
        }
    }
}

extension View {
    func loading(_ loading: Binding<Bool>) -> some View {
        modifier(LoadingViewModifier(isLoading: loading))
    }
}
