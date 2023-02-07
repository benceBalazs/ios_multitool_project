//
//  DetailedImageViewController.swift
//  multitoolProject
//
//  Created by Bence Balazs on 07.02.23.
//

import UIKit
import Photos

class DetailedImageViewController: UIViewController {
    
    var receivedAsset: PHAsset!
    
    @IBOutlet weak var shownImage: UIImageView!
    
    override func viewWillAppear(_ animated: Bool) {
            print("Test")
            print(receivedAsset!)
            shownImage.image = receivedAsset.requestImage()
            shownImage.contentMode = .scaleAspectFit
            shownImage.setNeedsDisplay()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

}
