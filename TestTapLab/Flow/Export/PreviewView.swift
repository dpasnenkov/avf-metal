//
//  PreviewView.swift
//  TestTapLab
//
//  Created by Dmitry Pasnenkov on 20/10/2023.
//

import UIKit
import AVFoundation

class PreviewView: UIView {
    private var playerLayer: AVPlayerLayer?

    override func layoutSubviews() {
        super.layoutSubviews()

        playerLayer?.frame = bounds
    }
}

extension PreviewView: PreviewOutput {
    func configure(with player: AVQueuePlayer?) {
        DispatchQueue.main.async { [weak self] in
            if self?.playerLayer == nil {
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.videoGravity = .resizeAspectFill

                self?.layer.addSublayer(playerLayer)
                self?.playerLayer = playerLayer
            }

            self?.layoutIfNeeded()
        }
    }
}
