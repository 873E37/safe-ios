//
//  NSMutableAttributedString+LineSpacing.swift
//  Multisig
//
//  Created by Mouaz on 9/8/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

extension NSMutableAttributedString {
    func lineSpacing(spacing: CGFloat = 22) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = spacing
        addAttribute(.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, length))
    }
}
