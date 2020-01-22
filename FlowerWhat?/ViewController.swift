//
//  ViewController.swift
//  FlowerWhat?
//
//  Created by Артём Шишкин on 19.01.2020.
//  Copyright © 2020 Артём Шишкин. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var flowerDescription: UILabel!
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
        
            guard let ciImage = CIImage(image: userPickedImage) else{
                fatalError("Cannot convert to CIImage.")
            }
            
            detect(image: ciImage)
            
            imageView.image = userPickedImage
            
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cameraButtonPressed(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func detect(image: CIImage){
        
        guard let model = try? VNCoreMLModel(for: FlowerClassified().model) else{
            fatalError("cannot import model")
        }
        
        let request = VNCoreMLRequest(model: model) {(request, error) in
            
            guard  let classification = request.results?.first as? VNClassificationObservation else{
                fatalError("can not classify image")
            }
            
            self.navigationItem.title = classification.identifier.capitalized
            self.wikiRequest(flowerName: classification.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch{
            print(error)
        }
    }
    
    func wikiRequest(flowerName:String){

        let wikipediaURL = "https://en.wikipedia.org/w/api.php"
        let parameters: [String: String] = [
            "format": "json",
            "action": "query",
            "prop": "extracts|pageimages",
            "exintro": "",
            "explaintext": "",
            "titles": flowerName,
            "indexpageids" : "",
            "redirects": "1",
            "pithumbsize": "500"]
        
        AF.request(wikipediaURL, parameters: parameters).responseJSON { (response) in

            switch response.result {
            
            case .success(_):
                
                let json: JSON = JSON(response.value!)

                let pageid = json["query"]["pageids"][0].stringValue

                let flowerInfo = json["query"]["pages"][pageid]["extract"].stringValue
                
                let flowerImage = json["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string: flowerImage))
                
                print(flowerInfo)
                print(json)
                self.flowerDescription.text = flowerInfo
                
                
            case .failure(_):
                print("cannot got a wiki info")
            }
        }
    }
    
    
    

}

