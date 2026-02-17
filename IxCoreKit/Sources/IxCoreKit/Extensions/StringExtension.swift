//
//  StringExtension.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 03/02/26.
//

import Foundation
import UIKit

public extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }

    var emoji: String? {
        first(where: { $0.isEmoji }).map { String($0) }
    }
}

extension String {
    func height(using font: UIFont, width: CGFloat) -> CGFloat {
        let rect = (self as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(rect.height)
    }

    func heightLimited(using font: UIFont, width: CGFloat, maxLines: Int) -> CGFloat {
        let lineHeight = font.lineHeight
        let fullHeight = height(using: font, width: width)
        return min(fullHeight, CGFloat(maxLines) * lineHeight)
    }
}
