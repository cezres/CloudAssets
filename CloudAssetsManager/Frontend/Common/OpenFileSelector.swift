//
//  OpenFileSelector.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/7.
//

import Foundation
import SwiftUI

struct OpenFileSelector: View {
    @Binding var url: URL?
    
    let title: String
    var panel: NSOpenPanel? = nil
    var isAutoHide = true
    
    func setAutoHide(_ isAutoHide: Bool = true) -> Self {
        .init(url: $url, title: title, panel: panel, isAutoHide: isAutoHide)
    }

    func configurationOpenPanel(_ handler: (_ panel: NSOpenPanel) -> Void) -> Self {
        let openPanel = panel ?? defaultOpenPanel()
        handler(openPanel)
        return .init(url: $url, title: title, panel: openPanel, isAutoHide: isAutoHide)
    }

    private func defaultOpenPanel() -> NSOpenPanel {
        let panel = NSOpenPanel()
        panel.title = title
        return panel
    }
        
    var body: some View {
        if url == nil || !isAutoHide {
            Button {
                let panel = panel ?? defaultOpenPanel()
                guard panel.runModal() == .OK else {
                    return
                }
                guard let url = panel.url else {
                    return
                }
                self.url = url
            } label: {
                if #available(macOS 12.0, *) {
                    Text(title)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.blue)
                } else {
                    Text(title)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }
            .buttonStyle(.borderless)
            .cornerRadius(8)
        }
    }
}
