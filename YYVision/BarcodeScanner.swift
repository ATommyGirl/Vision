//
//  BarcodeScanner.swift
//  YYVision
//
//  Created by YYLittleCat on 2023/11/24.
//

import AVFoundation
import UIKit
import AudioToolbox

protocol BarcodeScannerDelegate: NSObjectProtocol {
    func didScannedBarcode(_: BarcodeScanner, result: String)
    func failScanBarcode(_: BarcodeScanner, error: String)
    func didCancelScan(_: BarcodeScanner)
}

class BarcodeScanner: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var sessionQueue: DispatchQueue!
    var delegate: BarcodeScannerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "扫一扫"
        let backButton = UIBarButtonItem(image: UIImage.init(named: "goback"), style: .plain, target: self, action: #selector(backButtonTapped))
        self.navigationItem.leftBarButtonItem = backButton
        let titleTextAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white]
        let barTintColor = UIColor.clear
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = barTintColor
        appearance.backgroundEffect = nil
        appearance.titleTextAttributes = titleTextAttributes
        appearance.shadowColor = nil
        appearance.shadowImage = UIImage()
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.view.backgroundColor = UIColor.black
        
        // 创建捕获会话
        captureSession = AVCaptureSession()
        
        // 获取默认的设备（例如后置摄像头）
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        // 创建输入对象
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        // 创建输出对象
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            // 设置在主线程中执行代理方法
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        sessionQueue = DispatchQueue.init(label: "com.yyscanner.session.queue")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 创建预览层并添加到视图
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        startRunning()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func openScanner() -> UINavigationController {
        let nav = UINavigationController.init(rootViewController: self)
        nav.modalPresentationStyle = .fullScreen
        
        return nav
    }
    
    func closeScanner() {
        if ((self.navigationController?.presentingViewController) != nil) {
            self.navigationController?.dismiss(animated: true)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
        stopRunning()
    }
    
    func startRunning() {
        // 开始捕获
        self.sessionQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopRunning() {
        // 停止捕获
        self.sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func sucess(_ result: String) {
        self.delegate?.didScannedBarcode(self, result: result)
        self.closeScanner()
    }
    
    func failed() {
        self.delegate?.failScanBarcode(self, error: "请检查您的设备是否支持摄像头并已允许访问")
        captureSession = nil
        self.closeScanner()
    }
    
    @objc func backButtonTapped() {
        closeScanner()
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            DispatchQueue.main.async {
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                self.sucess(stringValue)
            }
        }
    }
    
    // 确保在控制器销毁时停止捕获
    deinit {
        if let session = captureSession, session.isRunning {
            session.stopRunning()
        }
    }
}
