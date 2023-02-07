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
    
    @IBOutlet weak var commonPhotoStorage: UILabel!
    @IBOutlet weak var livePhotoStorage: UILabel!
    @IBOutlet weak var panoramaStorage: UILabel!
    @IBOutlet weak var videoStorage: UILabel!
    
    @IBAction func loadEverything(_ sender: UIButton) {
        commonPhoto.text = "TestText"
        loadAllInformations()
        var cap = getStorageCapacity()
        print("Capacity : \(cap) MiB")
        var freeCap = getFreeStorageCapacity()
        print("Free capacity : \(freeCap) MiB")


    }
    
    @IBAction func deleteEverything(_ sender: UIButton) {
        deleteAllImages()
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
        /*
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
         */
        
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
        
        /*
        print("Debug \(fetchResult.count)")
        iterateOverMediatype(fetchResult)
        */
         
        print("Image \(fetchResultImage.count)")
        iterateOverMediatype(fetchResultImage)
        commonPhoto.text = "Normal images: \(fetchResultImage.count)"
        
        print("Pano \(fetchResultPano.count)")
        iterateOverMediatype(fetchResultPano)
        panorama.text = "Panorama images: \(fetchResultPano.count)"

        print("LivePhoto \(fetchResultLivePhoto.count)")
        iterateOverMediatype(fetchResultLivePhoto)
        livePhoto.text = "Live images: \(fetchResultLivePhoto.count)"

        print("Video \(fetchResultVideo.count)")
        getMemoryUsageVideo(fetchResultVideo)
        video.text = "Videos: \(fetchResultVideo.count)"

    }
    
    func iterateOverMediatype(_ fetchResult: PHFetchResult<PHAsset>){
        if(fetchResult.count > 0){
            for i in 0..<fetchResult.count{
                let asset = fetchResult.object(at: i)
                let memoryUsage = getMemoryUsage(for: asset)
                //Byte to MiB
                let fileSize = (Double(memoryUsage) / 1048576.0)
                print(fileSize)
                print(asset.value(forKey: "filename") as? String ?? "Nil")
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
    
    func deleteAllImages(){
        let fetchOptions = PHFetchOptions()
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        var assetsToDelete = [PHAsset]()
        fetchResult.enumerateObjects { (asset, _, _) in
            assetsToDelete.append(asset)
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSArray)
        }, completionHandler: {success, error in
            if success {
                print("All photos deleted successfully")
            } else {
                print("Error deleting photos")
            }
        })
    }
    
    func getStorageCapacity() -> Int{
        let fileManager = FileManager.default
        
        do{
            let attributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
            let totalSpace = attributes[FileAttributeKey.systemSize] as? NSNumber
            let spaceInBytes = totalSpace?.int64Value
            print("Total space: \(spaceInBytes ==  0) bytes")
            return Int(spaceInBytes! / 1048576)
        } catch {
            print("Error reading file system attributes: \(error)")
        }
        return 0
    }
    
    func getFreeStorageCapacity() -> Int{
        let fileManager = FileManager.default
        
        do{
            let attributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
            let totalSpace = attributes[FileAttributeKey.systemFreeSize] as? NSNumber
            let spaceInBytes = totalSpace?.int64Value
            print("Total space: \(spaceInBytes ==  0) bytes")
            return Int(spaceInBytes! / 1048576)
        } catch {
            print("Error reading file system attributes: \(error)")
        }
        return 0
    }
}
