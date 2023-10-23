//
//  WriterService.swift
//  TestTapLab
//
//  Created by Dmitry Pasnenkov on 19/10/2023.
//

import AVFoundation

class WriterService {
    private var assetWriter: AVAssetWriter?
    private var assetWriterInput: AVAssetWriterInput?
    private var assetWriterAdapter: AVAssetWriterInputPixelBufferAdaptor?
    private var videoSettings: [String:Any]?
    private var videoPath: URL?
    private var startTime: Double?

    private var isRecording = false

    init?(with settings: [String:Any]?) {
        videoSettings = settings
    }

    func initializeWriter() async throws {
        guard let videoPath = try? prepareFileUrl(with: "record.mov") else {
            throw PipelineError.failedWriterStarting
        }

        let assetWriter = try AVAssetWriter(outputURL: videoPath, fileType: .mov)

        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings) // [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: 1920, AVVideoHeightKey: 1080])
        input.mediaTimeScale = CMTimeScale(bitPattern: 600)
        input.expectsMediaDataInRealTime = true
//        input.transform = CGAffineTransform(rotationAngle: .pi/2)

        let adapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)

        guard assetWriter.canAdd(input) else { throw PipelineError.failedWriterStarting }

        assetWriter.add(input)

        self.assetWriter = assetWriter
        self.assetWriterInput = input
        self.assetWriterAdapter = adapter
        self.videoPath = videoPath
    }

    func start() throws {
        Task {
            try await initializeWriter()

            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: .zero)

            isRecording = true
        }
    }

    func stop() async throws -> URL {
        guard
            let assetWriter,
            assetWriterInput?.isReadyForMoreMediaData == true,
            assetWriter.status != .failed
        else { throw PipelineError.failedWriterStopping }

        assetWriterInput?.markAsFinished()

        return await withCheckedContinuation { continuation in
            assetWriter.finishWriting { [weak self] in
                self?.assetWriter = nil
                self?.assetWriterInput = nil
                self?.startTime = nil
                self?.isRecording = false

                guard let url = self?.videoPath else { return }

                continuation.resume(returning: url)
            }
        }
    }
    
    private func prepareFileUrl(with name: String) throws -> URL {
        let documentsURL = try FileManager.default.url(for: .documentDirectory,
                                                       in: .userDomainMask,
                                                       appropriateFor: nil,
                                                       create: true)

        let url = documentsURL.appendingPathComponent(name)

        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        return url
    }
}

extension WriterService: RenderServiceDelegate {
    func captureOutput(sampleBuffer: CMSampleBuffer) {
        guard isRecording else { return }

        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds

        if startTime == nil {
            startTime = timestamp
        }

        if assetWriterInput?.isReadyForMoreMediaData == true,
           let startTime,
           let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let time = CMTime(seconds: timestamp - startTime, preferredTimescale: CMTimeScale(600))
            assetWriterAdapter?.append(imageBuffer, withPresentationTime: time)
        }
    }
}
