//
//  PipelineService.swift
//  TestTapLab
//
//  Created by Dmitry Pasnenkov on 19/10/2023.
//

import AVFoundation
import UIKit

enum PipelineError: Error {
    case failedRenderServiceInitialization
    case failedWriterServiceInitialization
    case failedWriterStarting
    case failedWriterStopping
}


class PipelineService {
    private let writerService: WriterService
    private let streamService: StreamService
    private let renderService: RenderService

    weak var metalOutput: MetalOutput? {
        didSet {
            renderService.metalOutput = metalOutput
        }
    }

    init() async throws {
        streamService = StreamService()
        try await streamService.configure()

        guard let renderService = RenderService() else { throw PipelineError.failedRenderServiceInitialization }

        guard let writerService = WriterService(with: streamService.videoSettings) else { throw PipelineError.failedWriterServiceInitialization }

        streamService.delegate = renderService
        renderService.delegate = writerService

        self.renderService = renderService
        self.writerService = writerService
    }

    func start() {
        streamService.start()
    }

    func stop() {
        streamService.stop()
    }

    func apply(effect: Effects) {
        renderService.currentEffect = effect
    }

    func startWriting() async throws {
        try writerService.start()
    }

    func stopWriting() async throws -> URL {
        try await writerService.stop()
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
