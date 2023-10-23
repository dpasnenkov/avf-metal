//
//  MetalView.swift
//  TestTapLab
//
//  Created by Dmitry Pasnenkov on 17/10/2023.
//

import UIKit

class MetalView: UIView {
    private var metalLayer: CAMetalLayer?

    override func layoutSubviews() {
        super.layoutSubviews()

        metalLayer?.frame = bounds
    }
}

extension MetalView: MetalOutput {
    func configure(with device: MTLDevice?) {
        DispatchQueue.main.async { [weak self] in
            if self?.metalLayer == nil {
                let metalLayer = CAMetalLayer()
                metalLayer.device = device
                metalLayer.pixelFormat = .bgra8Unorm
                metalLayer.framebufferOnly = true

                self?.layer.addSublayer(metalLayer)
                self?.metalLayer = metalLayer
            }

            self?.layoutIfNeeded()
        }
    }

    func nextDrawable() -> CAMetalDrawable? {
        self.metalLayer?.nextDrawable()
    }
}
