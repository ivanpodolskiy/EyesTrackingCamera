//
//  CameraViewController.swift
//  EyesTrackingCamera
//
//  Created by user on 21.03.2024.
//

import UIKit
import AVFoundation
import Vision

class CameraViewController: UIViewController  {
    private let cameraManager = CameraManager()
    private let networking = NetworkingService()
    
    private var faceLayers: [CAShapeLayer] = []
    private lazy var previewLayer =  AVCaptureVideoPreviewLayer(session: cameraManager.captureSession)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        cameraManager.delegate = self
        setupPreviewLayer()
        setSubviews()
        activateLayout()
    }
    private lazy var actionBottomBar: ActionBottomBar = {
        let view = ActionBottomBar()
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        view.layer.cornerRadius = 12
        return view
    }()
    
    private func setupPreviewLayer() {
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
    }
    private func setSubviews() {
        view.addSubview(actionBottomBar)
    }
    private func activateLayout() {
        NSLayoutConstraint.activate([
            actionBottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            actionBottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actionBottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            actionBottomBar.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.18),
        ])
    }
}

extension CameraViewController: BottomBarDelegate {
    func switchCamera() {
        cameraManager.switchCameraInput()
    }
    func takePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        cameraManager.photoOutput.capturePhoto(with: photoSettings, delegate: cameraManager)
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

extension CameraViewController: CameraManagerDelegate{
    func setPhoto(image: UIImage) {
        networking.uploadImage(image) { status in
            print ("uploadImage is \(status)")
        }
        actionBottomBar.updateLastImage(image)
    }
    
    func handleFaceDetectionObservations(observations: [VNFaceObservation]) {
        removeFaceLayers()
        
        for observation in observations {
            let faceRectConverted = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observation.boundingBox)
            let faceRectanglePath = CGPath(rect: faceRectConverted, transform: nil)
            updateFaceLayer(with: faceRectanglePath)
            
            guard let landmarks = observation.landmarks else { continue }
            guard let leftEye = landmarks.leftEye, let rightEye = landmarks.rightEye else { continue }
            
            self.handleLandmark(leftEye, faceBoundingBox: faceRectConverted)
            self.handleLandmark(rightEye, faceBoundingBox: faceRectConverted)
            
            let faceWidth = observation.boundingBox.width * self.view.frame.width
            let faceCenterX = observation.boundingBox.origin.x * self.view.frame.width + faceWidth / 2
            let leftEyeX = CGFloat(truncating: leftEye.normalizedPoints[0].x as NSNumber) * faceWidth + faceCenterX - faceWidth / 2
            let rightEyeX = CGFloat(truncating: rightEye.normalizedPoints[0].x as NSNumber) * faceWidth + faceCenterX - faceWidth / 2
            
            let distanceThreshold: CGFloat = 0.1 // Adjust as needed
            let isLookingAtCamera = abs(leftEyeX - rightEyeX) < faceWidth * distanceThreshold
            
            let faceYaw = observation.yaw ?? 0.0 // Get face yaw angle (head rotation)
            let isFacingCamera = abs(CGFloat(truncating: faceYaw)) < 0.2 // Adjust threshold as needed
            
            if isLookingAtCamera && isFacingCamera {
                actionBottomBar.changeEnabledActionButton(true)
                print("User is looking at the camera")
            } else {
                print("User is not looking at the camera")
                actionBottomBar.changeEnabledActionButton(false)
            }
        }
    }
    
    private func  removeFaceLayers() {
        faceLayers.forEach({ drawing in drawing.removeFromSuperlayer() })
    }
    
    private func updateFaceLayer(with faceRectanglePath: CGPath ) {
        let faceLayer = CAShapeLayer()
        faceLayer.path = faceRectanglePath
        faceLayer.fillColor = UIColor.clear.cgColor
        faceLayer.strokeColor = UIColor.yellow.cgColor
        
        self.faceLayers.append(faceLayer)
        self.view.layer.addSublayer(faceLayer)
    }
    
    private func handleLandmark(_ eye: VNFaceLandmarkRegion2D, faceBoundingBox: CGRect) {
        let landmarkPath = CGMutablePath()
        let landmarkPathPoints = eye.normalizedPoints
            .map({ eyePoint in
                CGPoint(
                    x: eyePoint.y * faceBoundingBox.height + faceBoundingBox.origin.x,
                    y: eyePoint.x * faceBoundingBox.width + faceBoundingBox.origin.y)
            })
        landmarkPath.addLines(between: landmarkPathPoints)
        landmarkPath.closeSubpath()
        updateEyesLayer(with: landmarkPath)
    }
    
    private func updateEyesLayer(with landmarkPath: CGPath ) {
        let landmarkLayer = CAShapeLayer()
        landmarkLayer.path = landmarkPath
        landmarkLayer.fillColor = UIColor.clear.cgColor
        landmarkLayer.strokeColor = UIColor.green.cgColor
        
        self.faceLayers.append(landmarkLayer)
        self.view.layer.addSublayer(landmarkLayer)
    }
}
