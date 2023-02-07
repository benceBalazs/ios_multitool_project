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
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var loadBtn: UIButton!
    @IBOutlet weak var saveBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
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
        DispatchQueue.global().async {
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            if(fetchResult.count > 0){
                for imageID in 0..<fetchResult.count{
                    let asset = fetchResult.object(at: imageID)
                    self.requestedAssets.append(asset)
                    let uiAsset = asset.requestImage()
                    self.requestedImages.append(self.resize(image: uiAsset))
                }
            }
            DispatchQueue.main.sync {
                self.tableView.reloadData()
                self.activate(self.saveBtn)
            }
        }
        

    /*    let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: handleFaceDetection)
        faceDetectionRequest.usesCPUOnly = true
        
        //create request handler
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        
        DispatchQueue.global().async {
            do {
                //send requests to handler
                try handler.perform([faceDetectionRequest])
            } catch let error as NSError {
                print("Error: \(error)")
                fatalError()
            }
        }*/
    }
    
    func handleFaceDetection(request: VNRequest, error: Error?) {
        var resultInfo = ""
        var img = UIImage()
        if request.results != nil {
            for ob in request.results as! [VNFaceObservation] {
                /*DispatchQueue.main.sync {
                    img = self.imageView.image!
                }*/
                resultInfo += "face at \(ob.boundingBox)\n"
                showImage(img: drawObservationOnImage(ob, img))
            }
        } else {
            print("no face found")
        }
    }
    
    func showImage(img: UIImage) {
        /*DispatchQueue.main.sync {
            self.imageView.image = img
            self.imageView.setNeedsDisplay()
        }*/
    }
    
    func drawObservationOnImage(_ face: VNFaceObservation, _ image: UIImage) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(image.size, true, 0.0)
        let context = UIGraphicsGetCurrentContext()

        // draw the image
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))

        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)

        // draw the face rect
        let w = face.boundingBox.size.width * image.size.width
        let h = face.boundingBox.size.height * image.size.height
        let x = face.boundingBox.origin.x * image.size.width
        let y = face.boundingBox.origin.y * image.size.height
        let faceRect = CGRect(x: x, y: y, width: w, height: h)
        context?.saveGState()
        context?.setStrokeColor(UIColor.red.cgColor)
        context?.setLineWidth(10)
        context?.addRect(faceRect)
        context?.drawPath(using: .stroke)
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
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
            print(requestedImage)
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
