//
//  UIImageView+CloudResources.swift
//  CloudResources
//
//  Created by azusa on 2022/6/12.
//

import Foundation
import UIKit

public extension UIImageView {
    func setCloudAsset(name: String) {
        let op = CloudAssets.shared.fetch(withAssetName: name) { [weak self] data, error in
            guard let weakself = self, let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                weakself.image = image
            }
        }
        op.cancel(onObjectRelease: self)
    }
}

extension Operation {
    func cancel(onObjectRelease object: NSObject) {
        object.addReleaseAction { [weak self] in
            self?.cancel()
        }
    }
}

extension NSObject {
    func addReleaseAction(_ action: () -> Void) {
        
    }
}
