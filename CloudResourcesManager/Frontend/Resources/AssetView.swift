//
//  AssetView.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/6.
//

import SwiftUI

struct AssetView: View, Equatable {
    static func == (lhs: AssetView, rhs: AssetView) -> Bool {
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
//                    .scaledToFit()
//                    .scaledToFill()
                    .aspectRatio(contentMode: .fit)
                    
                    .frame(width: 100, height: 100)
                    .clipped()
//                    .background(Color(red: 240/255.0, green: 240/255.0, blue: 240/255.0))
//                    .border(.gray, width: 1)

            } else {
                Text(resource.pathExtension.uppercased())
                    .font(.system(size: 34, weight: .bold))
                    .frame(width: 100, height: 100, alignment: .center)
//                    .background(Color(red: 240/255.0, green: 240/255.0, blue: 240/255.0))
//                    .border(.gray, width: 1)
            }
            Text(resource.name)
            Text(Version.intToString(resource.version))
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
                deleteAction(resource)
            } label: {
                Text("Delete")
            }
        }
    }
}

