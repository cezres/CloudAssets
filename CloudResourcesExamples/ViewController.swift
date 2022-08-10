//
//  ViewController.swift
//  CloudResourcesExamples
//
//  Created by azusa on 2022/6/12.
//

import UIKit
import CloudResources

class ViewController: UIViewController {
    
    let resources: CloudResources = .shared

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        Task.detached {
//            await
//        }
        self.resources.start(identifier: "iCloud.im.bycoin.ios", version: "3.2.1")
        
        if let view = view.viewWithTag(2233) {
            view.removeFromSuperview()
        } else {
            let imageView = UIImageView()
            imageView.frame = .init(x: 0, y: 0, width: 300, height: 300)
            imageView.center = view.center
            imageView.contentMode = .scaleAspectFit
            imageView.layer.borderColor = UIColor.red.cgColor
            imageView.layer.borderWidth = 1
            imageView.tag = 2233
            view.addSubview(imageView)
            
            imageView.setCloudAsset(name: "nft_3d_background")
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }

}

