//
//  ExportPresenter.swift
//  TestTapLab
//
//  Created by Dmitry Pasnenkov on 19/10/2023.
//

import AVFoundation
import UIKit
import Photos

protocol ExportPresenterView: AnyObject where Self: UIViewController {
    var previewOutput: PreviewOutput { get }
}

class ExportPresenter {
    private weak var view: ExportPresenterView?

    private var previewService: PreviewService?

    let videoPath: URL

    init(view: ExportPresenterView, videoPath: URL) {
        self.view = view
        self.videoPath = videoPath
    }

    func configure() {
        previewService = PreviewService(videoURL: videoPath)
        previewService?.previewOutput = view?.previewOutput
    }

    func startPreview() {
        self.previewService?.start()
    }

    func stopPreview() {
        self.previewService?.stop()
    }

    func export() {
        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            
            guard status == .authorized else { return }
            
            let activity = await UIActivityViewController(activityItems: [videoPath], applicationActivities: nil)
            await view?.present(activity, animated: true, completion: nil)
        }
    }
}
