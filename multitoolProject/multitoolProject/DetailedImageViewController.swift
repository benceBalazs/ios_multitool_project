//
//  DetailedImageViewController.swift
//  multitoolProject
//
//  Created by Bence Balazs on 07.02.23.
//

import UIKit
import Photos

class DetailedImageViewController: UIViewController {
    
    var receivedImage: UIImage!
    
    @IBOutlet weak var shownImage: UIImageView!
    
    override func viewWillAppear(_ animated: Bool) {
            print("Test")
            print(receivedImage!)
            shownImage.image = receivedImage
            shownImage.contentMode = .scaleAspectFit
            shownImage.setNeedsDisplay()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

}
