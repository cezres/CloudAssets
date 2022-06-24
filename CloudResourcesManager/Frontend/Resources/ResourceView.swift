//
//  ResourceView.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/6.
//

import SwiftUI
import CloudResourcesFoundation

struct ResourceView: View, Equatable {
    static func == (lhs: ResourceView, rhs: ResourceView) -> Bool {
        lhs.resource == rhs.resource && lhs.resource.checksum == rhs.resource.checksum
    }
    
    @State var resource: Resource
    @State var image: NSImage?
    
    var deleteAction: (_ asset: Resource) -> Void
    
    var body: some View {
        VStack {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipped()

            } else {
                Text(resource.pathExtension.uppercased())
                    .font(.system(size: 34, weight: .bold))
                    .frame(width: 100, height: 100, alignment: .center)
            }
            Text(resource.name)
            Text(Version.intVersionToString(resource.version))
                .font(.subheadline)
        }
        .frame(width: 120)
        .onAppear {
            guard self.image == nil else { return }
            
            if resource.pathExtension == "png" {
                Task {
                    if let data = resource.data(), let image = NSImage(data: data) {
                        DispatchQueue.main.async {
                            self.image = image
                        }
                    }
                }
            }
        }
        .contextMenu {
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(resource.name, forType: .string)
            } label: {
                Text("Copy Name")
            }
            Button {
                deleteAction(resource)
            } label: {
                Text("Delete")
            }
        }
    }
}

