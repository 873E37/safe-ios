//
//  UITableViewCell+UINib.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

extension UITableViewCell {
    class func nib() -> UINib {
        UINib(nibName: String(describing: self), bundle: Bundle(for: Self.self))
    }
}
