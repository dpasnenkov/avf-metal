//
//  ViewController.swift
//  TestTapLab
//
//  Created by Dmitry Pasnenkov on 17/10/2023.
//

import UIKit

class StreamViewController: UIViewController {
    @IBOutlet private weak var metalView: MetalView!
    @IBOutlet private weak var vhsEffectButton: UIButton!
    @IBOutlet private weak var recordButton: UIButton!
    @IBOutlet private weak var scaleSegmentedControl: UISegmentedControl!

    var presenter: StreamPresenter!

    override func viewDidLoad() {
        super.viewDidLoad()

        presenter = StreamPresenter(view: self)

        recordButton.backgroundColor = .red
        vhsEffectButton.backgroundColor = .white
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        presenter.startStream()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        presenter.stopStream()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        recordButton.layer.cornerRadius = recordButton.bounds.width / 2
        recordButton.layer.borderWidth = 1
        recordButton.layer.borderColor = UIColor.black.cgColor

        vhsEffectButton.layer.cornerRadius = vhsEffectButton.bounds.width / 2
        vhsEffectButton.layer.borderWidth = 1
        vhsEffectButton.layer.borderColor = UIColor.lightGray.cgColor
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ExportViewController {
            vc.presenter = presenter.exportPresenter(for: vc)
        }
    }

    @IBAction func recordButtonTapped(_ sender: UIButton) {
        sender.isSelected.toggle()

        sender.backgroundColor = sender.isSelected ? .green : .red

        presenter.record(sender.isSelected ? .start : .stop)
    }

    @IBAction func vhsEffectButtonDown(_ sender: UIButton) {
        presenter.effect(effect: .vhs)
    }

    @IBAction func vhsEffectButtonUp(_ sender: UIButton) {
        presenter.effect(effect: .none)
    }

    @IBAction func scaleSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        guard let mode = ScaleContentMode(rawValue: sender.selectedSegmentIndex) else { return }

        presenter.scaleContent(mode: mode)
    }
}

extension StreamViewController: StreamPresenterView {
    var metalOutput: MetalOutput? {
        metalView
    }
}
