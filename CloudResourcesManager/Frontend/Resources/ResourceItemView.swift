//
//  ResourceItemView.swift
//  CloudAssetsManager
//
//  Created by azusa on 2022/6/6.
//

import SwiftUI
import ComposableArchitecture

struct ResourceItemView: View {
//    static func == (lhs: ResourceItemView, rhs: ResourceItemView) -> Bool {
//        lhs.resource == rhs.resource && lhs.resource.fileChecksum == rhs.resource.fileChecksum
//    }
    
//    @State var resource: Resource
//    @State var image: NSImage?
    let store: Store<ResourceItemState, ResourceItemAction>
    
    var deleteAction: (_ asset: Resource) -> Void
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                if let image = viewStore.image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipped()

                } else {
                    Text(viewStore.resource.pathExtension.uppercased())
                        .font(.system(size: 34, weight: .bold))
                        .frame(width: 100, height: 100, alignment: .center)
                }
                Text(viewStore.resource.name)
                Text(Version.intVersionToString(viewStore.resource.version))
                    .font(.subheadline)
            }
            .frame(width: 120)
            .onAppear {
//                guard self.image == nil else { return }
                
                if viewStore.resource.pathExtension == "png" {
//                    Task {
//                        // TODO: xx
//                        if let data = viewStore.resource.data(try! .init(.inMemory)), let image = NSImage(data: data) {
//                            DispatchQueue.main.async {
//                                self.image = image
//                            }
//                        }
//                    }
                    viewStore.send(.loadThumbnail)
                }
            }
            .contextMenu {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(viewStore.resource.name, forType: .string)
                } label: {
                    Text("Copy Name")
                }
                Button {
                    deleteAction(viewStore.resource)
                } label: {
                    Text("Delete")
                }
            }
        }
    }
}

