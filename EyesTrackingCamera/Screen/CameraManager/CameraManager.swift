//
//  CameraManager.swift
//  EyesTrackingCamera
//
//  Created by user on 21.03.2024.
//

import UIKit
import AVFoundation
import Vision

protocol CameraManagerDelegate: AnyObject {
    func setPhoto(image: UIImage)
    func handleFaceDetectionObservations(observations: [VNFaceObservation])
}

final class CameraManager: NSObject {
    weak var delegate: CameraManagerDelegate?
    
    private var backCameraOn = true
    private var currentCamera: AVCaptureDevice?
    private var backCamera: AVCaptureDevice?
    private var frontCamera: AVCaptureDevice?
    
    private var backInput: AVCaptureInput!
    private var frontInput: AVCaptureInput!
    
    let captureSession = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    
    override init() {
        super.init()
        checkPermissions()
        startCaptureSession()
    }
    
    private func checkPermissions() {
        let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraAuthStatus {
        case .authorized: return
        case .denied: abort()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { authorized in
                if !authorized { abort() }
            }
        case .restricted: abort()
        default: fatalError()
            
        }
    }
    private func startCaptureSession() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            setupCaptureSession()
            self.captureSession.startRunning()
        }
    }
    private func setupCaptureSession() {
        self.captureSession.beginConfiguration()
        if self.captureSession.canSetSessionPreset(.photo) {
            self.captureSession.sessionPreset = .photo
        }
        self.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true
        
        self.setupInputs()
        self.setupOutputs()
        self.captureSession.commitConfiguration()
    }
    private func setupInputs() {
        guard let backCamera = getBackCamera(), let frontCamera = getFronCamera() else  { return }
        do {
            backInput = try AVCaptureDeviceInput(device: backCamera)
            guard captureSession.canAddInput(backInput) else { return }
            
            frontInput = try AVCaptureDeviceInput(device: frontCamera)
            guard captureSession.canAddInput(frontInput) else { return }
        } catch {
            fatalError("could not connect camera")
        }
        currentCamera = backCamera
        captureSession.addInput(backInput)
    }
    private func setupOutputs() {
        guard captureSession.canAddOutput(photoOutput) else { return}
        photoOutput.maxPhotoQualityPrioritization = .balanced
        captureSession.addOutput(photoOutput)
    }
    private func getBackCamera() -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera], mediaType: .video, position: .back)
        guard let device = discoverySession.devices.first else { return nil}
        return device
    }
    private func getFronCamera() -> AVCaptureDevice?  {
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        return device
    }
}

extension CameraManager {
    func switchCameraInput() {
        captureSession.beginConfiguration()
        if backCameraOn {
            captureSession.removeInput(backInput)
            captureSession.addInput(frontInput)
            currentCamera = frontCamera
        } else {
            captureSession.removeInput(frontInput)
            captureSession.addInput(backInput)
            currentCamera = backCamera
        }
        backCameraOn.toggle()
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoQueue"))
        captureSession.addOutput(videoOutput)
        
        photoOutput.connections.first?.isVideoMirrored = !backCameraOn
        captureSession.commitConfiguration()
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate  {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print("Fail to capture photo: \(String(describing: error))")
            return
        }
        guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else { return }
        let targetSize = CGSize(width: 300, height: 300)
        guard let resizedImage = image.resizeImage(to: targetSize) else { return }

        
        DispatchQueue.main.async {
            self.delegate?.setPhoto(image: resizedImage) // сетим фото на превью нижнего бара
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil) // сохраняем сделанное фото в галерею
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard  let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let request = VNDetectFaceLandmarksRequest { request, error in
            if let error = error {
                print("Failed to detect face:", error.localizedDescription)
                return
            }
            DispatchQueue.main.async {
                guard let observations = request.results as? [VNFaceObservation] else { return }
                self.delegate?.handleFaceDetectionObservations(observations: observations)
            }
        }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,orientation: .downMirrored, options: [:])
        do {
            try imageRequestHandler.perform([request])
        }catch {
            print("Failed to perform request:", error.localizedDescription)
        }
    }
}
