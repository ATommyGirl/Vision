//
//  ViewController.swift
//  YYVision
//
//  Created by YYLittleCat on 2023/11/22.
//

import UIKit
import PhotosUI

class ViewController: UIViewController, PHPickerViewControllerDelegate, BarcodeScannerDelegate, BarcodeDetectorDelegate {
    
    @IBOutlet weak var resultTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func openScanner(_ sender: Any) {
        let scanner = BarcodeScanner()
        scanner.delegate = self
        present(scanner.openScanner(), animated: true)
    }
    
    @IBAction func openImagePicker(_ sender: Any) {
        let imagePicker = PHPickerViewController(configuration: PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared()))
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = .fullScreen
        present(imagePicker, animated: true)
    }
    
    @IBAction func clear(_ sender: Any) {
        resultTextView.text = nil
    }
    
    func appendText(_ text: String) {
        var temp = resultTextView.text ?? ""
        
        if temp.isEmpty {
            temp = text
        } else {
            temp = text + "\n" + temp
        }
        
        resultTextView.text = temp
        resultTextView.setContentOffset(.zero, animated: true)
    }
    
    // MARK: - BarcodeScannerDelegate
    
    func didScannedBarcode(_: BarcodeScanner, result: String) {
        self.appendText("✅ Scanner result - \n 〽️" + result)
    }
    
    func failScanBarcode(_: BarcodeScanner, error: String) {
        self.appendText("⚠️ Scanner error - " + error)
    }
    
    func didCancelScan(_: BarcodeScanner) {
        self.appendText("⭕️ Scanner cancelled.")
    }
    
    func didDetectedBarcode(_: BarcodeDetector, result: String) {
        self.appendText(result)
    }
    
    func failDetectBarcode(_: BarcodeDetector, error: String) {
        self.appendText("⚠️ Detector error - " + error)
    }
    
    func didCancelDetect(_: BarcodeDetector) {
        self.appendText("⭕️ Detector cancelled.")
    }
    
    // MARK: - PHPickerViewControllerDelegate
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        DispatchQueue.main.async {
            picker.dismiss(animated: true, completion: nil)

            guard let selectedResult = results.first else {
                return
            }

//            selectedResult.itemProvider.loadObject(ofClass: UIImage.self) { (loadedImage, error) in
//                DispatchQueue.main.async {
//                    guard let selectedImage = loadedImage else {
//                        print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
//                        return
//                    }
//
//                    let detector = BarcodeDetector()
//                    detector.img = loadedImage
//                    detector.modalPresentationStyle = .fullScreen
//                    self.present(detector, animated: true)
//                }
//            }
            
            selectedResult.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                DispatchQueue.main.async {
                    guard let selectedImage = UIImage(data: data!) else {
                        print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }

                    let detector = BarcodeDetector()
                    detector.img = selectedImage
                    detector.delegate = self
                    detector.modalPresentationStyle = .fullScreen
                    self.present(detector.openPreview(), animated: true)
                }
            }
            
            selectedResult.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                if let error = error {
                    print("Error loading file representation: \(error)")
                    return
                }

                if let url = url {
                    print("Selected image URL: \(url)")
                }
            }
        }
    }
}

