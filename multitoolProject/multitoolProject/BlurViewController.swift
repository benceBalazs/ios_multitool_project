//
//  ViewController.swift
//  multitoolProject
//
//  Created by Bence Balazs on 06.02.23.
//

import UIKit
import Vision
import Photos

class BlurViewController: UIViewController {
    
    var requestedImages: [UIImage]!
    var validImages: [UIImage]!
    var requestedTitles: [String]!
    var validTitles: [String]!
    let cellReuseIdentifier = "faceCell"
    var selectedImage: Int!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var loadBtn: UIButton!
    @IBOutlet weak var saveBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetData()
        tableView.delegate = self
        tableView.dataSource = self
        activityIndicator.isHidden = true
        deactivate(saveBtn)
    }
    
    func deactivate(_ btn: UIButton){
        btn.isUserInteractionEnabled = false
        btn.isHidden = true
    }
    
    func activate(_ btn: UIButton){
        btn.isUserInteractionEnabled = true
        btn.isHidden = false
    }

    func showAlertWith(title: String, message: String){
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    @IBAction func saveImages(_ sender: UIButton) {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                for index in 0..<self.validImages.count {
                    let imageData = self.validImages[index].jpegData(compressionQuality: 1.0)!
                    let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(self.validTitles[index]).jpeg")
                    try? imageData.write(to: fileURL)
                    PHPhotoLibrary.requestAuthorization { status in
                        if status == .authorized {
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetCreationRequest.creationRequestForAssetFromImage(atFileURL: fileURL)
                            }) { success, error in
                                if success {
                                    print("The image was saved to the photo gallery.")
                                } else {
                                    print("Error saving the image to the photo gallery: \(error?.localizedDescription ?? "")")
                                }
                            }
                        }
                    }
                }
                DispatchQueue.main.sync {
                    self.activityIndicator.isHidden = true
                    self.activityIndicator.stopAnimating()
                    self.showAlertWith(title: "Gallery", message: "Successfully saved all \(self.validTitles!.count) images to the gallery")
                    self.resetData()
                    self.tableView.reloadData()
                    self.deactivate(self.saveBtn)
                }
            } else {
                print("STATUS: \(status)")
            }
        }
    }
    
    func resetData() {
        self.requestedImages = [UIImage]()
        self.validImages = [UIImage]()
        self.requestedTitles = [String]()
        self.validTitles = [String]()
        self.selectedImage = 0
    }
    
    @IBAction func loadImages(_ sender: UIButton) {
        self.resetData()
        let fetchOptions: PHFetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: handleFaceDetection)
        faceDetectionRequest.usesCPUOnly = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        DispatchQueue.global(qos: .userInitiated).async {
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            if(fetchResult.count > 0){
                for imageID in 0..<fetchResult.count{
                    let asset = fetchResult.object(at: imageID)
                    let uiAsset = asset.requestImage()
                    self.requestedImages.append(uiAsset)
                    self.requestedTitles.append("\((asset.value(forKey: "filename") as? String)!)_edited")
                    let handler = VNImageRequestHandler(cgImage: self.requestedImages[imageID].cgImage!, options: [:])
                    do {
                        try handler.perform([faceDetectionRequest])
                        self.selectedImage += 1
                    } catch let error as NSError {
                        print("Error: \(error)")
                        fatalError()
                    }
                }
                DispatchQueue.main.sync {
                    self.tableView.reloadData()
                    self.activate(self.saveBtn)
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                }
            }
        }
    }
    
    func handleFaceDetection(request: VNRequest, error: Error?) {
        if request.results != nil {
            if !request.results!.isEmpty {
                self.validImages.append(drawObservationOnImage(request.results as! [VNFaceObservation], requestedImages[self.selectedImage]))
                self.validTitles.append(self.requestedTitles[self.selectedImage])
            } else {
                print("NOFACEFOUND")
            }
        }
    }
    
    func drawObservationOnImage(_ faces: [VNFaceObservation], _ image: UIImage) -> UIImage{
        var ciImage = CIImage(cgImage: image.cgImage!)
        let blurFilter = CIFilter(name: "CIGaussianBlur")!
        blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
        for face in faces {
            let faceBounds = face.boundingBox
            let faceRect = CGRect(x: faceBounds.origin.x * ciImage.extent.size.width,
                                  y: (faceBounds.origin.y) * ciImage.extent.size.height,
                                  width: faceBounds.size.width * ciImage.extent.size.width,
                                  height: faceBounds.size.height * ciImage.extent.size.height)
            blurFilter.setValue(40, forKey: kCIInputRadiusKey)
            let blurredFaceImage = blurFilter.outputImage!.cropped(to: faceRect)
            ciImage = blurredFaceImage.composited(over: ciImage)
        }
        let resultImage = UIImage(ciImage: ciImage)
        return resultImage
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == "showDetailedImage" {
            if let vc = segue.destination as? DetailedImageViewController {
                vc.receivedImage = validImages[tableView.indexPathForSelectedRow!.row]
            }
        }
    }
    
    @IBAction func unwindToShowScreen(_ unwindSegue: UIStoryboardSegue) {
    }
    
    func resize(image: UIImage)-> UIImage{
        let size = CGSize(width: image.size.width/6, height: image.size.height/6)
        let renderer = UIGraphicsImageRenderer(size: size)
        let resizedImage = renderer.image { context in
            image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        return resizedImage
    }
}

extension PHAsset {
    func requestImage() -> UIImage {
        var requestedImage = UIImage()
        let imageManager = PHCachingImageManager()
        let options = PHImageRequestOptions()
        options.resizeMode = .fast
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat;
        imageManager.requestImageDataAndOrientation(for: self, options: options, resultHandler:    {(providedData, _, _, _) in
            requestedImage = UIImage(data: providedData!)!
        })
        return requestedImage
    }
}

extension BlurViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.validImages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:CustomTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! CustomTableViewCell
        if(self.validImages.count >= 0){
            cell.customImage.image = self.resize(image: validImages[indexPath.row])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            validImages.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Remove Selection"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

