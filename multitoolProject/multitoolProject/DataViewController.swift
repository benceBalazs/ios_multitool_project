//
//  DataViewController.swift
//  multitoolProject
//
//  Created by Bence Balazs on 06.02.23.
//

import UIKit
import Photos

class DataViewController: UIViewController {
    @IBOutlet weak var video: UILabel!
    @IBOutlet weak var panorama: UILabel!
    @IBOutlet weak var livePhoto: UILabel!
    @IBOutlet weak var commonPhoto: UILabel!
    
    @IBAction func loadEverything(_ sender: UIButton) {
        commonPhoto.text = "TestText"
        loadAllInformations()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func loadAllInformations(){
        //Image Data
        let fetchOptionsImage = PHFetchOptions()
        fetchOptionsImage.sortDescriptors = [NSSortDescriptor(key:"creationDate",ascending:false)]
        let fetchResultImage = PHAsset.fetchAssets(with: .image, options: fetchOptionsImage)
        
        //Debug Data
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        //Panorama Data
        let panoOptions = PHFetchOptions()
        panoOptions.predicate = NSPredicate(format: "mediaSubtype == %d", PHAssetMediaSubtype.photoPanorama.rawValue)
        let fetchResultPano = PHAsset.fetchAssets(with: .image, options: panoOptions)
        
        //LivePhoto Data
        let livePhotoOptions = PHFetchOptions()
        livePhotoOptions.predicate = NSPredicate(format: "mediaSubtype == %d", PHAssetMediaSubtype.photoLive.rawValue)
        let fetchResultLivePhoto = PHAsset.fetchAssets(with: .image, options: livePhotoOptions)
        
        //Video Data
        let fetchOptionsVideo = PHFetchOptions()
        fetchOptionsVideo.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        let fetchResultVideo = PHAsset.fetchAssets(with: .video, options: fetchOptionsVideo)
        
        print("Debug \(fetchResult.count)")
        iterateOverMediatype(fetchResult)
        
        print("Image \(fetchResultImage.count)")
        iterateOverMediatype(fetchResultImage)
        
        print("Pano \(fetchResultPano.count)")
        iterateOverMediatype(fetchResultPano)

        print("LivePhoto \(fetchResultLivePhoto.count)")
        iterateOverMediatype(fetchResultLivePhoto)
        
        print("Video \(fetchResultVideo.count)")
        getMemoryUsageVideo(fetchResultVideo)
    }
    
    func iterateOverMediatype(_ fetchResult: PHFetchResult<PHAsset>){
        if(fetchResult.count > 0){
            for i in 0..<fetchResult.count{
                let asset = fetchResult.object(at: i)
                let memoryUsage = getMemoryUsage(for: asset)
                //Byte to MiB
                let fileSize = (Double(memoryUsage) / 1048576.0)
                print(fileSize)
            }
            
        }else{
            print("No photos available")
        }
    }
    
    func getMemoryUsage(for asset: PHAsset) -> Int {
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        
        var imageData: Data?
        imageManager.requestImageDataAndOrientation(for: asset, options: requestOptions){(data, _, _, _) in
            imageData = data
        }
        return imageData?.count ?? 0
    }
    
    func getMemoryUsageVideo(_ fetchResult: PHFetchResult<PHAsset>){
        if fetchResult.count > 0 {
            for i in 0..<fetchResult.count {
                let asset = fetchResult.object(at:i)
                let resource = PHAssetResource.assetResources(for: asset).first
                let fileSize = resource?.value(forKey: "fileSize") as? Int
                //File in MiB
                let fileSizeInMB = Double(fileSize ?? 0) / (1024.0 * 1024.0)
                print("Video file size: \(fileSizeInMB) MiB")
            }
        } else {
            print("no videos found")
        }
    }
}
