//
//  RenderService.swift
//  TestTapLab
//
//  Created by Dmitry Pasnenkov on 19/10/2023.
//

import UIKit
import AVFoundation

protocol MetalOutput: AnyObject {
    func configure(with device: MTLDevice?)
    func nextDrawable() -> CAMetalDrawable?
}

protocol RenderServiceDelegate: AnyObject {
    func captureOutput(sampleBuffer: CMSampleBuffer)
}

enum Effects {
    case none
    case vhs
}

class RenderService {
    private let metalDevice = MTLCreateSystemDefaultDevice()
    private var textureCache: CVMetalTextureCache?
    private var displayRenderPipelineState: MTLRenderPipelineState?
    private var effectRenderPipelineState: MTLRenderPipelineState?

    var currentEffect: Effects = .none

    weak var delegate: RenderServiceDelegate?

    lazy private var commandQueue: MTLCommandQueue? = {
        return metalDevice?.makeCommandQueue()
    }()

    weak var metalOutput: MetalOutput? {
        didSet {
            metalOutput?.configure(with: metalDevice)
        }
    }

    init?() {

        guard
            let metalDevice = metalDevice,
            CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &textureCache) == kCVReturnSuccess
        else {
            return nil
        }

        initializeRenderPipelineState()
        initializeEffectRenderPipelineState()
    }

    private func initializeRenderPipelineState() {
            guard
                let device = metalDevice,
                let library = device.makeDefaultLibrary()
            else { return }

            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.rasterSampleCount = 1
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDescriptor.depthAttachmentPixelFormat = .invalid

            /**
             *  Vertex function to map the texture to the view controller's view
             */
            pipelineDescriptor.vertexFunction = library.makeFunction(name: "mapTexture")
            /**
             *  Fragment function to display texture's pixels in the area bounded by vertices of `mapTexture` shader
             */
            pipelineDescriptor.fragmentFunction = library.makeFunction(name: "displayTexture")

            do {
                try displayRenderPipelineState = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            }
            catch {
                assertionFailure("Failed creating a render state pipeline. Can't render the texture without one.")
                return
            }
        }

    private func initializeEffectRenderPipelineState() {
            guard
                let device = metalDevice,
                let library = device.makeDefaultLibrary()
            else { return }

            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.rasterSampleCount = 1
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDescriptor.depthAttachmentPixelFormat = .invalid

            /**
             *  Vertex function to map the texture to the view controller's view
             */
            pipelineDescriptor.vertexFunction = library.makeFunction(name: "mapTexture")
            /**
             *  Fragment function to display texture's pixels in the area bounded by vertices of `mapTexture` shader
             */
            pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_main")

            do {
                try effectRenderPipelineState = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            }
            catch {
                assertionFailure("Failed creating a render state pipeline. Can't render the texture without one.")
                return
            }
        }


    private func render(texture: MTLTexture, withCommandBuffer commandBuffer: MTLCommandBuffer, device: MTLDevice) {
        guard
            let currentDrawable = metalOutput?.nextDrawable()
        else {
            return
        }

        let currentRenderPassDescriptor = MTLRenderPassDescriptor()
        currentRenderPassDescriptor.colorAttachments[0].texture = currentDrawable.texture
        currentRenderPassDescriptor.colorAttachments[0].loadAction = .clear
//        currentRenderPassDescriptor.colorAttachments[0].storeAction = .store
        currentRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(  0.0,  0.0,  0.0,  0.0)

        guard
            let displayRenderPipelineState = displayRenderPipelineState,
            let effectRenderPipelineState = effectRenderPipelineState,
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: currentRenderPassDescriptor)
        else {
            return
        }

        encoder.pushDebugGroup("RenderFrame")
        encoder.setRenderPipelineState(displayRenderPipelineState)
//        encoder.setRenderPipelineState(effectRenderPipelineState)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
        encoder.popDebugGroup()
        encoder.endEncoding()

//        commandBuffer.addScheduledHandler { [weak self] (buffer) in
//        }

        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }

    func filter(inputTexture: MTLTexture) -> CVPixelBuffer? {
//        let textureDescriptor = MTLTextureDescriptor()
//
//        textureDescriptor.pixelFormat = .bgra8Unorm
//        textureDescriptor.height = inputTexture.height
//        textureDescriptor.width = inputTexture.width
//
//        guard let outputTexture = metalDevice?.makeTexture(descriptor: textureDescriptor) else { return nil }
//
//        // Set up command queue, buffer, and encoder.
//        guard let commandQueue = commandQueue,
//            let commandBuffer = commandQueue.makeCommandBuffer(),
//            let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
//                print("Failed to create a Metal command queue.")
//                CVMetalTextureCacheFlush(textureCache!, 0)
//                return nil
//        }
//
//        commandEncoder.label = "VHS"
////        commandEncoder.setComputePipelineState(computePipelineState!)
//        commandEncoder.setTexture(inputTexture, index: 0)
//        commandEncoder.setTexture(outputTexture, index: 1)
//
//        commandEncoder.endEncoding()
//        commandBuffer.commit()
//        return outputPixelBuffer

        return nil
    }
}

extension RenderService: StreamServiceDelegate {
    func captureOutput(sampleBuffer: CMSampleBuffer) {
        autoreleasepool {
            guard
                let textureCache,
                let texture = sampleBuffer.toMetalTexture(with: textureCache)
            else { return }

            guard
                let device = metalDevice,
                let commandBuffer = commandQueue?.makeCommandBuffer()
            else {
                return
            }

//            filter(inputTexture: texture)

            render(texture: texture, withCommandBuffer: commandBuffer, device: device)
        }

        delegate?.captureOutput(sampleBuffer: sampleBuffer)
    }
}

extension CMSampleBuffer {
    func toMetalTexture (with textureCache: CVMetalTextureCache)  -> MTLTexture? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(self) else {
            return nil
        }

        let isPlanar = CVPixelBufferIsPlanar(imageBuffer)
        let width = isPlanar ? CVPixelBufferGetWidthOfPlane(imageBuffer, 0) : CVPixelBufferGetWidth(imageBuffer)
        let height = isPlanar ? CVPixelBufferGetHeightOfPlane(imageBuffer, 0) : CVPixelBufferGetHeight(imageBuffer)

        var imageTexture: CVMetalTexture?

        let result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, imageBuffer, nil, .bgra8Unorm, width, height, 0, &imageTexture)

        guard
            let unwrappedImageTexture = imageTexture,
            let texture = CVMetalTextureGetTexture(unwrappedImageTexture),
            result == kCVReturnSuccess
        else {
            return nil
        }

        return texture
    }
}
