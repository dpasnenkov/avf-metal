//
//  ExportViewController.swift
//  TestTapLab
//
//  Created by Dmitry Pasnenkov on 19/10/2023.
//

import UIKit
import AVFoundation

class ExportViewController: UIViewController {
    var presenter: ExportPresenter!

    @IBOutlet private weak var previewView: PreviewView!

    override func viewDidLoad() {
        super.viewDidLoad()

        presenter.configure()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        presenter.startPreview()
    }


    @IBAction func exportButtonTapped(_ sender: Any) {
        presenter.export()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}

extension ExportViewController: ExportPresenterView {
    var previewOutput: PreviewOutput {
        previewView
    }
}
