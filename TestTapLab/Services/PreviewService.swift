//
//  PreviewService.swift
//  TestTapLab
//
//  Created by Dmitry Pasnenkov on 19/10/2023.
//

import AVFoundation
import UIKit

protocol PreviewOutput: AnyObject {
    func configure(with player: AVQueuePlayer?)
}

class PreviewService {
    private var avPlayer: AVQueuePlayer?
    private var playerItem: AVPlayerItem?
    private var playerLooper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?

    weak var previewOutput: PreviewOutput? {
        didSet {
            previewOutput?.configure(with: avPlayer)
        }
    }

    init?(videoURL: URL) {
        let asset = AVAsset(url: videoURL)
        let playerItem = AVPlayerItem(asset: asset)
        let avPlayer = AVQueuePlayer(playerItem: playerItem)

        playerLooper = AVPlayerLooper(player: avPlayer, templateItem: playerItem)

        self.playerItem = playerItem
        self.avPlayer = avPlayer
    }

    func start() {
        avPlayer?.play()
    }

    func stop() {
        avPlayer?.pause()
    }
}

//class PreviewService {
//    private var displayLink: CADisplayLink?
//    private var output: AVPlayerItemVideoOutput!
//    private var avPlayer: AVPlayer?
////    private var context: CIContext = CIContext(options: [CIContextOption.workingColorSpace: NSNull()])
//    private var playerItemObserver: NSKeyValueObservation?
//    private var videoDidPlayedObserver: NSObjectProtocol?
//
//    weak var previewOutput: AVSampleBufferDisplayLayer?
//
//    init?(videoURL: URL) {
//        let asset = AVAsset(url: videoURL)
//        let playerItem = AVPlayerItem(asset: asset)
//        let settings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: Int32(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange))]
//        output = AVPlayerItemVideoOutput(outputSettings: nil)
//        playerItem.add(output)
//
//        playerItemObserver = playerItem.observe(\.status) { [weak self] item, _ in
//            guard item.status == .readyToPlay else { return }
//            self?.playerItemObserver = nil
//            self?.setupDisplayLink()
//        }
//
//        let avPlayer = AVPlayer(playerItem: playerItem)
////        avPlayer.volume = 0.5
//
//        videoDidPlayedObserver = NotificationCenter.default.addObserver(
//            forName: .AVPlayerItemDidPlayToEndTime,
//            object: playerItem,
//            queue: .main
//        ) { [weak self] _ in
//                    self?.restart()
//        }
//
//        self.avPlayer = avPlayer
//    }
//
//    deinit {
//        NotificationCenter.default.removeObserver(self)
//    }
//
//    private func setupDisplayLink() {
//        if let displayLink {
//            displayLink.invalidate()
//        }
//        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkUpdated(link:)))
//        displayLink?.preferredFramesPerSecond = 30
//        displayLink?.add(to: .main, forMode: RunLoop.Mode.common)
//    }
//
//    @objc private func displayLinkUpdated(link: CADisplayLink) {
//        let time = output.itemTime(forHostTime: CACurrentMediaTime())
//
//        guard
//            output.hasNewPixelBuffer(forItemTime: time),
//            let pixelBuffer = output.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil),
//            let sampleBuffer = pixelBuffer.createSampleBuffer(with: time)
//        else { return }
//
//
////        let image = CIImage(cvPixelBuffer: pixelBuffer)
//
//        previewOutput?.sampleBufferRenderer.enqueue(sampleBuffer)
//        previewOutput?.setNeedsDisplay()
//    }
//
//    public func restart() {
//        avPlayer?.seek(to: CMTime.zero)
//        avPlayer?.play()
//    }
//
//    public func start() {
//        setupDisplayLink()
//
//        avPlayer?.play()
//    }
//
//    public func cancel() {
//        if let displayLink {
//            displayLink.invalidate()
//        }
//
//        avPlayer?.pause()
//    }
//}
//
//extension CVPixelBuffer {
//    func createSampleBuffer(with time: CMTime) -> CMSampleBuffer? {
//        var sampleBuffer: CMSampleBuffer?
//
//        var timimgInfo  = CMSampleTimingInfo(
//            duration: .invalid,
//            presentationTimeStamp: time,
//            decodeTimeStamp: .invalid
//        )
//
//        var formatDescription: CMFormatDescription? = nil
//        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: self, formatDescriptionOut: &formatDescription)
//
//        let osStatus = CMSampleBufferCreateReadyWithImageBuffer(
//          allocator: kCFAllocatorDefault,
//          imageBuffer: self,
//          formatDescription: formatDescription!,
//          sampleTiming: &timimgInfo,
//          sampleBufferOut: &sampleBuffer
//        )
//
//        // Print out errors
//        if osStatus == kCMSampleBufferError_AllocationFailed {
//          print("osStatus == kCMSampleBufferError_AllocationFailed")
//        }
//        if osStatus == kCMSampleBufferError_RequiredParameterMissing {
//          print("osStatus == kCMSampleBufferError_RequiredParameterMissing")
//        }
//        if osStatus == kCMSampleBufferError_AlreadyHasDataBuffer {
//          print("osStatus == kCMSampleBufferError_AlreadyHasDataBuffer")
//        }
//        if osStatus == kCMSampleBufferError_BufferNotReady {
//          print("osStatus == kCMSampleBufferError_BufferNotReady")
//        }
//        if osStatus == kCMSampleBufferError_SampleIndexOutOfRange {
//          print("osStatus == kCMSampleBufferError_SampleIndexOutOfRange")
//        }
//        if osStatus == kCMSampleBufferError_BufferHasNoSampleSizes {
//          print("osStatus == kCMSampleBufferError_BufferHasNoSampleSizes")
//        }
//        if osStatus == kCMSampleBufferError_BufferHasNoSampleTimingInfo {
//          print("osStatus == kCMSampleBufferError_BufferHasNoSampleTimingInfo")
//        }
//        if osStatus == kCMSampleBufferError_ArrayTooSmall {
//          print("osStatus == kCMSampleBufferError_ArrayTooSmall")
//        }
//        if osStatus == kCMSampleBufferError_InvalidEntryCount {
//          print("osStatus == kCMSampleBufferError_InvalidEntryCount")
//        }
//        if osStatus == kCMSampleBufferError_CannotSubdivide {
//          print("osStatus == kCMSampleBufferError_CannotSubdivide")
//        }
//        if osStatus == kCMSampleBufferError_SampleTimingInfoInvalid {
//          print("osStatus == kCMSampleBufferError_SampleTimingInfoInvalid")
//        }
//        if osStatus == kCMSampleBufferError_InvalidMediaTypeForOperation {
//          print("osStatus == kCMSampleBufferError_InvalidMediaTypeForOperation")
//        }
//        if osStatus == kCMSampleBufferError_InvalidSampleData {
//          print("osStatus == kCMSampleBufferError_InvalidSampleData")
//        }
//        if osStatus == kCMSampleBufferError_InvalidMediaFormat {
//          print("osStatus == kCMSampleBufferError_InvalidMediaFormat")
//        }
//        if osStatus == kCMSampleBufferError_Invalidated {
//          print("osStatus == kCMSampleBufferError_Invalidated")
//        }
//        if osStatus == kCMSampleBufferError_DataFailed {
//          print("osStatus == kCMSampleBufferError_DataFailed")
//        }
//        if osStatus == kCMSampleBufferError_DataCanceled {
//          print("osStatus == kCMSampleBufferError_DataCanceled")
//        }
//
//        guard let buffer = sampleBuffer else {
//          print("Cannot create sample buffer")
//          return nil
//        }
//
//        return buffer
//      }
//}
