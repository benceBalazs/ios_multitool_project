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

    var animals: [String] = ["Horse", "Cow", "Camel", "Sheep", "Goat"]
    var requestedImages = [UIImage]()
    var requestedAssets = [PHAsset]()
    let cellReuseIdentifier = "CustomCell"
    var selectedImage = 0
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var loadBtn: UIButton!
    @IBOutlet weak var saveBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        activityIndicator.isHidden = true
        deactivate(saveBtn)
    }
    
    func deactivate(_ btn: UIButton){
        btn.isUserInteractionEnabled = false
        btn.isHidden = true
        //btn.backgroundColor = UIColor.gray
    }
    
    func activate(_ btn: UIButton){
        btn.isUserInteractionEnabled = true
        btn.isHidden = false
        //btn.backgroundColor = UIColor.systemBlue
    }

    @IBAction func saveImages(_ sender: UIButton) {
        
    }
    
    @IBAction func loadImages(_ sender: UIButton) {
        let fetchOptions: PHFetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: handleFaceDetection)
        faceDetectionRequest.usesCPUOnly = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        DispatchQueue.global(qos: .userInteractive).async {
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            if(fetchResult.count > 0){
                for imageID in 0..<fetchResult.count{
                    let asset = fetchResult.object(at: imageID)
                    self.requestedAssets.append(asset)
                    let uiAsset = asset.requestImage()
                    self.requestedImages.append(self.resize(image: uiAsset))
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
            requestedImages[self.selectedImage] = drawObservationOnImage(request.results as! [VNFaceObservation], requestedImages[self.selectedImage])
        } else {
            print("no face found")
        }
    }
    
    func drawObservationOnImage(_ faces: [VNFaceObservation], _ image: UIImage) -> UIImage{
        var newImage = image
        var finalImage = CIImage()
        
        UIGraphicsBeginImageContextWithOptions(image.size, true, 0.0)
        let context = UIGraphicsGetCurrentContext()
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
                   
        for face in faces {
            let w = face.boundingBox.size.width * image.size.width
            let h = face.boundingBox.size.height * image.size.height
            let x = face.boundingBox.origin.x * image.size.width
            let y = face.boundingBox.origin.y * image.size.height
            
            let faceRect = UIImageView(frame: CGRect(x: x, y: y, width: w, height: h))
            
            let faceMask = CIImage(color: CIColor(red: 1, green: 1, blue: 1, alpha: 1)).cropped(to: faceRect)
            newImage = applyMaskedVariableBlur(image: newImage, mask: faceMask)
            faceMask.applyingGaussianBlur(sigma: 30.0)

            context?.saveGState()
            context?.setStrokeColor(UIColor.red.cgColor)
            context?.setLineWidth(5)
            context?.addRect(faceRect)
        }

        context?.drawPath(using: .stroke)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
        
        
        
//        return UIImage(ciImage: finalImage)
    }
    

    
    func applyMaskedVariableBlur(image:UIImage, mask:CIImage) -> UIImage {

        let filter = CIFilter(name: "CIMaskedVariableBlur")

        // convert UIImages to CIImages and set as input

        let ciInput = CIImage(image: image)
        let ciMask = mask
        filter?.setValue(ciInput, forKey: "inputImage")
        filter?.setValue(ciMask, forKey: "inputMask")

        // get output CIImage, render as CGImage first to retain proper UIImage scale
        
        
        
        let ciOutput = filter?.outputImage
        let ciContext = CIContext()
        let cgImage = ciContext.createCGImage(ciOutput!, from: (ciOutput?.extent)!)

        return UIImage(cgImage: cgImage!)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == "showDetailedImage" {
            //let controller = segue.destination
            if let vc = segue.destination as? DetailedImageViewController {
                vc.receivedAsset = requestedAssets[tableView.indexPathForSelectedRow!.row]
            }
        }
    }
    
    @IBAction func unwindToShowScreen(_ unwindSegue: UIStoryboardSegue) {
        //let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
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
        /*imageManager.requestImage(for: self, targetSize: CGSize(width:1200, height:1200), contentMode: .aspectFit, options: nil, resultHandler: { providedImage, _ in
            requestedImage = providedImage!
        })*/
        imageManager.requestImageDataAndOrientation(for: self, options: options, resultHandler:    {(providedData, _, _, _) in
            requestedImage = UIImage(data: providedData!)!
        })
        return requestedImage
    }
}

extension BlurViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.requestedImages.count
    }
    
    // Make the background color show through
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:CustomTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! CustomTableViewCell
        if(self.requestedImages.count >= 0){
            cell.customImage.image = requestedImages[indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {
            requestedImages.remove(at: indexPath.row)
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

extension UIImage{
    func drawImageInRect(inputImage: UIImage, inRect imageRect: CGRect) -> UIImage {
        UIGraphicsBeginImageContext(self.size)
        self.draw(in: CGRect(x: 0.0, y: 0.0, width: self.size.width, height: self.size.height))
        inputImage.draw(in: imageRect)
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return UIImage() }
        UIGraphicsEndImageContext()
        return newImage
    }
}
