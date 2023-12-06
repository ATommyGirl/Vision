//
//  PeopleZing.swift
//  YYVision
//
//  Created by YYLittleCat on 2023/12/4.
//

import UIKit
import CoreML
import Vision

class PeopleZing: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    var selectedRect: CGRect?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 1.0
        imageView.addGestureRecognizer(longPressGesture)
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            // 长按开始，执行人体检测
            detectPeople()
        } else if gesture.state == .ended {
            // 长按结束，处理拖动或其他操作
        }
    }
    
    func detectPeople() {
        guard let image = imageView.image else { return }
        
        let model = try? VNCoreMLModel(for: MobileNetV2().model)
        let request = VNCoreMLRequest(model: model!) { [weak self] request, error in
            self?.processDetectionResults(for: request, error: error)
        }
        
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, orientation: CGImagePropertyOrientation.up)
        do {
            try handler.perform([request])
        } catch {
            print("Error performing vision request: \(error)")
        }
    }
    
    func processDetectionResults(for request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNRecognizedObjectObservation], !results.isEmpty else {
            print("No results")
            return
        }
        
        // 从结果中获取人体边界框
        if let firstResult = results.first {
            selectedRect = firstResult.boundingBox
            highlightDetectedArea()
        }
    }
    
    func highlightDetectedArea() {
        guard let rect = selectedRect else { return }
        
        let highlightedRect = CGRect(
            x: rect.origin.x * imageView.bounds.width,
            y: (1 - rect.origin.y - rect.height) * imageView.bounds.height,
            width: rect.width * imageView.bounds.width,
            height: rect.height * imageView.bounds.height
        )
        
        // 在 imageView 上绘制一个透明的蓝色矩形以表示检测到的人体
        let overlayView = UIView(frame: highlightedRect)
        overlayView.layer.borderWidth = 2.0
        overlayView.layer.borderColor = UIColor.blue.cgColor
        overlayView.backgroundColor = UIColor.blue.withAlphaComponent(0.2)
        imageView.addSubview(overlayView)
    }
}
