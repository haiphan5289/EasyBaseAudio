//
//  LabelExtension.swift
//  baominh_ios
//
//  Created by haiphan on 01/11/2021.
//

import Foundation
import UIKit

public extension UILabel {
    func underlineMyText(listRange:[String]) {
        if let textString = self.text {

            let str = NSString(string: textString)
            let attributedString = NSMutableAttributedString(string: textString)
            
            listRange.forEach { text in
                let textColor: UIColor = .red
                let underLineColor: UIColor = .red
                let underLineStyle = NSUnderlineStyle.single.rawValue
                let range = str.range(of: text)
                let labelAtributes:[NSAttributedString.Key : Any]  = [
                    NSAttributedString.Key.foregroundColor: textColor,
                    NSAttributedString.Key.underlineStyle: underLineStyle,
                    NSAttributedString.Key.underlineColor: underLineColor
                    ]
                attributedString.addAttributes(labelAtributes, range: range)
                attributedText = attributedString
            }
        }
    }
}
