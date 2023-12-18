//
//  BarcodeDetector.swift
//  YYVision
//
//  Created by YYLittleCat on 2023/11/27.
//

import UIKit
import CoreImage
import AVFoundation
import Vision

struct Barcode {
    var count: Int
    var ciRect: CGRect
    var result: String?
    var error: String?
}

protocol BarcodeDetectorDelegate: NSObjectProtocol {
    func didDetectedBarcode(_: BarcodeDetector, result: String)
    func failDetectBarcode(_: BarcodeDetector, error: String)
    func didCancelDetect(_: BarcodeDetector)
}

class BarcodeDetector: UIViewController {
    
    var activity: UIActivityIndicatorView!
    var imgV: UIImageView!
    var url: URL?
    var img: UIImage?
    var delegate: BarcodeDetectorDelegate?
    var orientation: CGImagePropertyOrientation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backButton = UIBarButtonItem(image: UIImage.init(named: "goback"), style: .plain, target: self, action: #selector(backButtonTapped))
        let doneButton = UIBarButtonItem(title: "完成", style: .plain, target: self, action: #selector(doneButtonTapped))
        doneButton.tintColor = .systemGreen
        navigationItem.leftBarButtonItem = backButton
        navigationItem.rightBarButtonItem = doneButton
        
        let titleTextAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white]
        let barTintColor = UIColor.gray
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = barTintColor
        appearance.backgroundEffect = nil
        appearance.titleTextAttributes = titleTextAttributes
        appearance.shadowColor = nil
        appearance.shadowImage = UIImage()
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.setNavigationBarHidden(false, animated: true)
        view.backgroundColor = UIColor.black
        
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        indicator.color = UIColor.systemGreen
        indicator.hidesWhenStopped = true
        navigationItem.titleView = indicator
        activity = indicator
        
        let imageView = UIImageView.init(frame: view.bounds)
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        imgV = imageView
        imgV.image = img
    }
    
    func startDetectAnimate() {
        activity.isHidden = false
        if !activity.isAnimating {
            activity.startAnimating()
        }
    }

    func stopDetectAnimate() {
        if activity.isAnimating {
            activity.stopAnimating()
        }
    }
    
    func openPreview() -> UINavigationController {
        let nav = UINavigationController.init(rootViewController: self)
        nav.modalPresentationStyle = .fullScreen
        
        return nav
    }
    
    func closePreview() {
        if ((self.navigationController?.presentingViewController) != nil) {
            self.navigationController?.dismiss(animated: true)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func backButtonTapped() {
        delegate?.didCancelDetect(self)
        stopDetectAnimate()
        closePreview()
    }
    
    @objc func doneButtonTapped() {
        navigationItem.rightBarButtonItem?.isEnabled = false
        startDetectAnimate()
        detectBarcodeFromImg(img!) { [weak self] barcode in
            DispatchQueue.main.async {
                self!.stopDetectAnimate()
                self!.handleDetectResult(barcode)
            }
        }
    }
    
    func handleDetectResult(_ barcode: Barcode) {
        if let error = barcode.error {
            delegate?.failDetectBarcode(self, error: error)
            closePreview()
        }
        else if barcode.count == 1 {
            delegate?.didDetectedBarcode(self, result: barcode.result!)
            closePreview()
        }
        else {
            let boundingBox = convertCIBoundingRectToUIRect(barcode.ciRect)
            
            let view = UIView(frame: boundingBox)
            view.backgroundColor = .orange.withAlphaComponent(0.6)
            imgV.addSubview(view)
            
            let centerX = CGRectGetMidX(boundingBox)
            let centerY = CGRectGetMidY(boundingBox)
            let centerPoint = CGPoint(x: centerX, y: centerY)
            let go = BCAnimationButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            go.center = centerPoint
            go.payload = barcode.result
            go.addTarget(self, action: #selector(animationButtonAction), for: .touchUpInside)
            imgV.addSubview(go)
        }
    }
    
    // MARK - Rect
    
    @objc func animationButtonAction(_ sender: BCAnimationButton) {
        delegate?.didDetectedBarcode(self, result: sender.payload!)
        closePreview()
    }
    
    func convertCIBoundingRectToUIRect(_ cii: CGRect) -> CGRect {
        let renderingRect = imgV.renderingRectForImage()
        
        let ci = cii.applying(getCGAffineTransform(from: orientation!))

        let w = ci.size.width * renderingRect!.size.width
        let h = ci.size.height * renderingRect!.size.height
        let x = ci.origin.x * renderingRect!.size.width + renderingRect!.origin.x
        let y = ci.origin.y * renderingRect!.size.height + renderingRect!.origin.y
        
        return CGRectMake(x, y, w, h)
    }
    
    // MARK - Detecting
    
    func detectBarcodeFromImg(_ oriImg: UIImage, _ completion: @escaping (Barcode) -> Void) {
        guard let oriCG = oriImg.cgImage else {
            completion(Barcode(count: 0, ciRect: .null, result: nil, error: "Image not available!"))
            return
        }
        
        DispatchQueue.init(label: "com.yydetector.session.queue").async { [self] in
            let tempBgCG = imageFromColor(.white, size: CGSize.init(width: oriCG.width, height: oriCG.height)).cgImage!
            var newImg = drawImage(oriCG, toCenter: tempBgCG)
            guard let buffer = pixelBuffer(from: newImg!) else {
                newImg = nil
                completion(Barcode(count: 0,
                                   ciRect: .null,
                                   result: nil,
                                   error: "Image type not support!"))
                return
            }
            
            /*
            // 获取图片属性
            guard let imageSource = CGImageSourceCreateWithDataProvider(oriCG.dataProvider!, nil) else {
                print("Failed to create image source")
                return
            }
            
            var properties = CGImageSourceCopyPropertiesAtIndex(imageSource, CGImageSourceGetCount(imageSource) - 1, nil) as? [String: Any]
            if (properties != nil) {
                print("Image Properties:")
                for (key, value) in properties! {
                    print("\(key): \(value)")
                }
            } else {
                properties = ["" : ""]
                print("Failed to retrieve image properties")
            }
            
            let requestHandler = VNImageRequestHandler.init(cvPixelBuffer: buffer, options: [VNImageOption.properties : properties as Any])
            */
            
            let tempOrientation = getCGImagePropertyOrientation(from: oriImg.imageOrientation)
            orientation = tempOrientation
            let requestHandler = VNImageRequestHandler.init(cvPixelBuffer: buffer, orientation: tempOrientation)

//            let requestHandler = VNImageRequestHandler.init(cvPixelBuffer: buffer)
            do {
                let detectRequest = VNDetectBarcodesRequest { [self] request, error in
                    if let error = error {
                        completion(Barcode(count: 0,
                                           ciRect: .null,
                                           result: nil,
                                           error: error.localizedDescription))
                        print("Error in text recognition: \(error.localizedDescription)")
                        return
                    }
                    
                    if request.results!.isEmpty {
                        completion(Barcode(count: 0,
                                           ciRect: .null,
                                           result: nil,
                                           error: "No result of request!"))
                        return
                    }
                    
                    for case let barcode as VNBarcodeObservation in request.results! {
                        if barcode.payloadStringValue != nil {
                            let formatter = printBarcode(barcode)
                            completion(Barcode(count: request.results!.count,
                                               ciRect: barcode.boundingBox,
                                               result: formatter,
                                               error: nil))
                        } else {
                            completion(Barcode(count: request.results!.count,
                                               ciRect: .null,
                                               result: nil,
                                               error: "No payload string value!"))
                        }
                    }
                }
                
                try requestHandler.perform([detectRequest])
            } catch {
                completion(Barcode(count: 0, ciRect: .null, result: nil, error: error.localizedDescription))
            }
        }
    }
    
    func printBarcode(_ barcode: VNBarcodeObservation) -> String {
        let rect = String(format: "\n\t x = %0.3f, \n\t y = %0.3f, \n\t w = %0.3f, \n\t h = %0.3f", barcode.boundingBox.origin.x, barcode.boundingBox.origin.y, barcode.boundingBox.size.width, barcode.boundingBox.size.height)
        let rectPra = String(format: "\n 〽️confidence = %0.1f, \n 〽️boundingBox = %@", barcode.confidence, rect)
        
        var barcodeDescriptor = ""
        if let qrCodeDescriptor = barcode.barcodeDescriptor as? CIQRCodeDescriptor {
            let payload = String(data: qrCodeDescriptor.errorCorrectedPayload, encoding: .utf8) ?? ""
            barcodeDescriptor = String(format: "\n\t symbolVersion = %ld, \n\t maskPattern = %d, \n\t errorCorrectionLevel = %ld, \n\t errorCorrectedPayload = %@", qrCodeDescriptor.symbolVersion, qrCodeDescriptor.maskPattern, qrCodeDescriptor.errorCorrectionLevel.rawValue, payload)
        }
        
        let formatter = String(format: "\n------------------------\n✅ VNBarcodeObservation:\n 〽️value = %@, \n 〽️type = %@, %@, \n 〽️desc : %@ \n------------------------,", barcode.payloadStringValue ?? "", barcode.symbology as CVarArg, rectPra, barcodeDescriptor)
        
        print(formatter)
        return formatter
    }
    
    func imageFromColor(_ color: UIColor, size: CGSize) -> UIImage! {
        let rect = CGRect(x: 0, y: 0, width: size.width + 10, height: size.height + 10)
        
        UIGraphicsBeginImageContext(rect.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return UIImage(named: "scan_bg")
        }
        
        context.setFillColor(color.cgColor)
        context.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func drawImage(_ oriImg: CGImage, toCenter bgImg: CGImage) -> UIImage? {
        let targetSize = CGSize(width: CGFloat(bgImg.width), height: CGFloat(bgImg.height))
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        
        let bottomImage = UIImage(cgImage: bgImg)
        bottomImage.draw(in: CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height))
        
        let scaledSize = CGSize(width: CGFloat(oriImg.width), height: CGFloat(oriImg.height))
        let destinationRect = CGRect(
            x: (targetSize.width - scaledSize.width) / 2,
            y: (targetSize.height - scaledSize.height) / 2,
            width: scaledSize.width,
            height: scaledSize.height
        )
        
        let centeredImage = UIImage(cgImage: oriImg)
        centeredImage.draw(in: destinationRect)
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage
    }

    func pixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        guard let cgImage = image.cgImage else {
            return nil
        }

        let options: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(image.size.width),
                                         Int(image.size.height),
                                         kCVPixelFormatType_32ARGB,
                                         options as CFDictionary,
                                         &pixelBuffer)

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                width: Int(image.size.width),
                                height: Int(image.size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)

        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))

        return buffer
    }
    
    func getCGImagePropertyOrientation(from uiImageOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiImageOrientation {
        case .up:
            return .up
        case .down:
            return .down
        case .left:
            return .left
        case .right:
            return .right
        case .upMirrored:
            return .upMirrored
        case .downMirrored:
            return .downMirrored
        case .leftMirrored:
            return .leftMirrored
        case .rightMirrored:
            return .rightMirrored
        @unknown default:
            return .up //不返回错误，默认按照 up
        }
    }
    
    func getCGAffineTransform(from orientation: CGImagePropertyOrientation) -> CGAffineTransform {
        switch orientation {
        case .up, .down:
            return CGAffineTransform(scaleX: 1, y: 1).translatedBy(x: 0, y: 0)//.
        default:
            return CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1)//.

        /*
        case .left, .right:
            return CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1)
        case .upMirrored:
            return CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1)
        case .downMirrored:
            return CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1)
        case .leftMirrored:
            return CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1)
        case .rightMirrored:
            return CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1)
         */
        }
    }
}
