//
//  ExportService.swift
//  TestTapLab
//
//  Created by Dmitry Pasnenkov on 19/10/2023.
//

import AVFoundation

class ExportService {
    func export(videoPath: URL, at outputURL: URL) async  -> URL? {
        let asset = AVAsset(url: videoPath)

        guard let exporter = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetHEVCHighestQuality
        ) else {
            return nil
        }

        exporter.outputURL = outputURL
        exporter.outputFileType = .mp4
        exporter.shouldOptimizeForNetworkUse = true

        return await withCheckedContinuation { continuation in
            exporter.exportAsynchronously {
                if exporter.status == .completed {
                    continuation.resume(returning: exporter.outputURL)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
