//
//  AddKeyAsNewOwnerViewController.swift
//  Multisig
//
//  Created by Vitaly on 25.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddKeyAsNewOwnerViewController: UIViewController, UIAdaptivePresentationControllerDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!

    var onAdd: (() -> ())?

    var onReplace: (() -> ())?

    var onSkip: (() -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()

        presentationController?.delegate = self

        titleLabel.setStyle(.primary)
        descriptionLabel.setStyle(.secondary)
        addButton.setText("Add as owner", .filled)
        skipButton.setText("Skip", .plain)
    }

    // Called when user swipes down the modal screen
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        onSkip?()
    }

    @IBAction func didTapAddButton(_ sender: Any) {
        addOwnerAction()

    }

    @IBAction func didTapSkipButton(_ sender: Any) {
        onSkip?()
    }

    func addOwnerAction() {

        let alertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet)

        let add = UIAlertAction(title: "Add new owner", style: .default) { [unowned self] _ in
            guard alertController.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "Add new owner" else {
                return
            }
            self.onAdd?()
        }

        let replace = UIAlertAction(title: "Replace owner", style: .default) { [unowned self] _ in
            guard alertController.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "Replace owner" else {
                return
            }
            self.onReplace?()
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(add)
        alertController.addAction(replace)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }
}
