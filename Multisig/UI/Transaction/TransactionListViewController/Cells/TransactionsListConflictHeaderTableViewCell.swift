//
//  TransactionsListConflictHeaderTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 12/15/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class TransactionsListConflictHeaderTableViewCell: UITableViewCell, ExternalURLSource {
    @IBOutlet private weak var nonceLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var learnMoreButton: UIButton!
    private(set) var url: URL? = App.configuration.help.conflictURL

    override func awakeFromNib() {
        super.awakeFromNib()
        nonceLabel.setStyle(.footnote2)
        descriptionLabel.setStyle(.footnote2)
        let buttonFont = UIFont.gnoFont(forTextStyle: .footnote2)
        learnMoreButton.setText("Learn more", GNOButtonStyle.plain.font(buttonFont))
    }

    func set(nonce: String) {
        nonceLabel.text = nonce
    }

    @IBAction func learnMoreButtonTouched(_ sender: Any) {
        openExternalURL()
    }
}
