//
//  StreamPresenter.swift
//  TestTapLab
//
//  Created by Dmitry Pasnenkov on 17/10/2023.
//

import UIKit

enum ScaleContentMode: Int {
    case scaleToFill = 0
    case scaleAspectFit
    case scaleAspectFill
}

enum RecordingState {
    case start
    case stop
}

protocol StreamPresenterView: AnyObject where Self: UIViewController {
    var metalOutput: MetalOutput? { get }
}

class StreamPresenter {
    private var pipelineService: PipelineService?
    private var scaleContentMode: ScaleContentMode

    private weak var view: StreamPresenterView?
    private var videoPath: URL?

    init(view: StreamPresenterView) {
        self.view = view
        self.scaleContentMode = .scaleToFill
    }

    func record(_ state: RecordingState) {
        Task {
            switch state {
            case .start:
                try? await pipelineService?.startWriting()
            case.stop:
                videoPath = try? await pipelineService?.stopWriting()
                await view?.performSegue(withIdentifier: "goToExport", sender: view)
            }
        }
    }

    func effect(effect: Effects) {
        pipelineService?.apply(effect: effect)
    }

    func scaleContent(mode: ScaleContentMode) {
        scaleContentMode = mode
    }

    func startStream() {
        Task { [weak self] in
            if self?.pipelineService == nil {
                self?.pipelineService = try? await PipelineService()
                self?.pipelineService?.metalOutput = self?.view?.metalOutput
            }

            self?.pipelineService?.start()
        }
    }

    func stopStream() {
        pipelineService?.stop()
    }

    func exportPresenter(for view: ExportPresenterView) -> ExportPresenter? {
        guard let videoPath else { return nil }

        return ExportPresenter(view: view, videoPath: videoPath)
    }
}
