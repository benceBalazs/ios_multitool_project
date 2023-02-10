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
    
    @IBOutlet weak var storage: UILabel!
    @IBOutlet weak var freeStorage: UILabel!
    
    private var commonPhotos = [PHAsset]()
    
    @IBAction func loadEverything(_ sender: UIButton) {
        commonPhoto.text = "TestText"
        loadAllInformations()
        let cap = getStorageCapacity()
        print("Capacity : \(cap) MiB")
        let freeCap = getFreeStorageCapacity()
        print("Free capacity : \(freeCap) MiB")
    }
    
    @IBAction func deleteEverything(_ sender: UIButton) {
        deleteAllImages(commonPhotos)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func loadAllInformations(){
        
        //Image Data
        let fetchOptionsImage = PHFetchOptions()
        fetchOptionsImage.sortDescriptors = [NSSortDescriptor(key:"creationDate",ascending:false)]
        let fetchResultImage = PHAsset.fetchAssets(with: .image, options: fetchOptionsImage)
        
        //LivePhoto Data
        let livePhotoOptions = PHFetchOptions()
        livePhotoOptions.predicate = NSPredicate(format: "mediaSubtype == %d", PHAssetMediaSubtype.photoLive.rawValue)
        let fetchResultLivePhoto = PHAsset.fetchAssets(with: .image, options: livePhotoOptions)
        
        //Panorama Data
        let panoOptions = PHFetchOptions()
        panoOptions.predicate = NSPredicate(format: "mediaSubtype == %d", PHAssetMediaSubtype.photoPanorama.rawValue)
        let fetchResultPano = PHAsset.fetchAssets(with: .image, options: panoOptions)

        //Video Data
        let fetchOptionsVideo = PHFetchOptions()
        fetchOptionsVideo.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        let fetchResultVideo = PHAsset.fetchAssets(with: .video, options: fetchOptionsVideo)
        
        //Images without Live and Panorama
        commonPhotos = getCommonImages(fetchResultImage, fetchResultLivePhoto, fetchResultPano)
        print("Image \(commonPhotos.count)")
        let memoryUsageCommonPhoto = round(iterateOverMediatypePHAssets(commonPhotos)*10)/10
        commonPhotoStorage.text = "\(memoryUsageCommonPhoto) in MiB"
        commonPhoto.text = "Normal images: \(commonPhotos.count)"
        
        print("LivePhoto \(fetchResultLivePhoto.count)")
        let memoryUsageLivePhoto = round(iterateOverMediatype(fetchResultLivePhoto)*10)/10
        livePhotoStorage.text = "\(memoryUsageLivePhoto) in MiB"
        livePhoto.text = "Live images: \(fetchResultLivePhoto.count)"

        print("Pano \(fetchResultPano.count)")
        let memoryUsagePanorama = round(iterateOverMediatype(fetchResultPano)*10)/10
        panoramaStorage.text = "\(memoryUsagePanorama) in MiB"
        panorama.text = "Panorama images: \(fetchResultPano.count)"
        
        print("Video \(fetchResultVideo.count)")
        let memoryUsageVideo = round(getMemoryUsageVideo(fetchResultVideo)*10)/10
        videoStorage.text = "\(memoryUsageVideo) in MiB"
        video.text = "Videos: \(fetchResultVideo.count)"
        
        let storageCapacity = getStorageCapacity()
        let freeStorageCapacity = getFreeStorageCapacity()
        
        storage.text = "Gesamtkapazität: \(storageCapacity) MiB"
        freeStorage.text = "Freier Speicher: \(freeStorageCapacity) MiB"
    }
    
    func iterateOverMediatype(_ fetchResult: PHFetchResult<PHAsset>) -> Double{
        if(fetchResult.count > 0){
            var totalMemory = 0.0
            for i in 0..<fetchResult.count{
                let asset = fetchResult.object(at: i)
                let memoryUsage = getMemoryUsage(for: asset)
                //Byte to MiB
                let fileSize = (Double(memoryUsage) / 1048576.0)
                totalMemory += fileSize
                print(fileSize)
                print(asset.value(forKey: "filename") as? String ?? "Nil")
                print(asset.localIdentifier)
            }
            return totalMemory
        }else{
            print("No photos available")
            return 0.0
        }
    }
    
    func iterateOverMediatypePHAssets(_ fetchResult: [PHAsset]) -> Double{
        if(fetchResult.count > 0){
            var totalMemory = 0.0
            for i in 0..<fetchResult.count{
                let asset = fetchResult[i]
                let memoryUsage = getMemoryUsage(for: asset)
                //Byte to MiB
                let fileSize = (Double(memoryUsage) / 1048576.0)
                totalMemory += fileSize
                print(fileSize)
                print(asset.value(forKey: "filename") as? String ?? "Nil")
                print(asset.localIdentifier)
            }
            return totalMemory
        }else{
            print("No photos available")
            return 0.0
        }
    }
    
    func getCommonImages(_ commonImageResult: PHFetchResult<PHAsset>,_ livePhotoResult: PHFetchResult<PHAsset>,_ panoramaResult: PHFetchResult<PHAsset>) -> [PHAsset]{
        var onlyImages: [PHAsset] = [PHAsset]()
        for i in 0..<commonImageResult.count{
            let x = commonImageResult.object(at: i)
            var isUnique = true;
            for j in 0..<livePhotoResult.count{
                let live = livePhotoResult.object(at: j)
                if(x.localIdentifier == live.localIdentifier){
                    isUnique = false
                }
            }
            for j in 0..<panoramaResult.count{
                let pano = panoramaResult.object(at: j)
                if(x.localIdentifier == pano.localIdentifier){
                    isUnique = false
                }
            }
            if(isUnique){
                onlyImages.append(x)
            }
        }
        return onlyImages
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
    
    func getMemoryUsageVideo(_ fetchResult: PHFetchResult<PHAsset>) -> Double{
        if fetchResult.count > 0 {
            var totalMemory = 0.0
            for i in 0..<fetchResult.count {
                let asset = fetchResult.object(at:i)
                let resource = PHAssetResource.assetResources(for: asset).first
                let fileSize = resource?.value(forKey: "fileSize") as? Int
                //File in MiB
                let fileSizeInMB = Double(fileSize ?? 0) / (1024.0 * 1024.0)
                print("Video file size: \(fileSizeInMB) MiB")
                totalMemory += fileSizeInMB
            }
            return totalMemory
        } else {
            print("No videos found")
            return 0.0
        }
    }
    
    func deleteAllImages(_ assetsToDelete: [PHAsset]){
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSArray)
        }, completionHandler: {success, error in
            if success {
                print("All photos deleted successfully")
                DispatchQueue.main.sync {
                    self.loadAllInformations()
                }
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
