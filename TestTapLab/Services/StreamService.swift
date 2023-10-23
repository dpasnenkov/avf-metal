//
//  StreamService.swift
//  TestTapLab
//
//  Created by Dmitry Pasnenkov on 18/10/2023.
//

import AVFoundation
import UIKit

enum StreamServiceError: Error {
    case noAccess
    case startError
}

protocol StreamServiceDelegate: AnyObject {
     func captureOutput(sampleBuffer: CMSampleBuffer)
}

class StreamService: NSObject {
    private var session = AVCaptureSession()
    private var camera: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let streamQueue = DispatchQueue(label: "StreamQueue", attributes: [])
    private let pixelFormat = kCVPixelFormatType_32BGRA
    private var textureCache: CVMetalTextureCache?

    weak var delegate: StreamServiceDelegate?

    var videoSettings: [String: Any]? {
        videoOutput?.recommendedVideoSettingsForAssetWriter(writingTo: .mov)
    }

    private var defaultCamera: AVCaptureDevice? {
        // Find the built-in Dual Camera, if it exists.
        if let device = AVCaptureDevice.default(.builtInDualCamera,
                                                for: .video,
                                                position: .back) {
            return device
        }

        // Find the built-in Wide-Angle Camera, if it exists.
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                for: .video,
                                                position: .back) {
            return device
        }

        return nil
    }

    private func configureService() {
        guard
            let camera = defaultCamera,
            let videoInput = try? AVCaptureDeviceInput(device: camera)
        else { return }

        let videoOutput = AVCaptureVideoDataOutput()

        self.camera = camera

        if let videoInput = self.videoInput {
            session.removeInput(videoInput)
        }
        if let videoOutput = self.videoOutput {
            session.removeOutput(videoOutput)
        }

        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.hd1920x1080

        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(pixelFormat)
        ]
//        videoOutput.alwaysDiscardsLateVideoFrames = true

        videoOutput.setSampleBufferDelegate(self, queue: streamQueue)
        


        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        self.videoInput = videoInput
        self.videoOutput = videoOutput

        session.commitConfiguration()

        session.beginConfiguration()
        if let connection = videoOutput.connection(with: .video),
            connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        session.commitConfiguration()
    }

    func configure() async throws {
        try await requestCameraAccess()

        streamQueue.async {
            self.configureService()
        }

    }

    func requestCameraAccess() async throws {
        guard
            await AVCaptureDevice.requestAccess(for: .video),
            await AVCaptureDevice.requestAccess(for: .audio)
        else {
            throw StreamServiceError.noAccess
        }
    }

    func start() {
        streamQueue.async {
            self.session.startRunning()
        }
    }

    func stop() {
        streamQueue.async {
            self.session.stopRunning()
        }
    }

    deinit {
    }
}

extension StreamService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.captureOutput(sampleBuffer: sampleBuffer)
    }
}
