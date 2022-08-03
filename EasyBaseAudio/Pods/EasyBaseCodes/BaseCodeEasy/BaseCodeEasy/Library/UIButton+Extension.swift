//
//  UIButton+Extension.swift
//  Dayshee
//
//  Created by paxcreation on 1/8/21.
//  Copyright © 2021 ThanhPham. All rights reserved.
//

import UIKit

public class HighlightedButton: UIButton {

    public override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? .red : .blue
        }
    }
}
@IBDesignable
public extension UIButton {
    /// SwifterSwift: Border color of view; also inspectable from Storyboard.
    @IBInspectable override var borderColor: UIColor? {
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
        set {
            guard let color = newValue else {
                layer.borderColor = nil
                return
            }
            // Fix React-Native conflict issue
            guard String(describing: type(of: color)) != "__NSCFType" else { return }
            layer.borderColor = color.cgColor
        }
    }
//
//    /// SwifterSwift: Border width of view; also inspectable from Storyboard.
//    @IBInspectable var borderWidth: CGFloat {
//        get {
//            return layer.borderWidth
//        }
//        set {
//            layer.borderWidth = newValue
//        }
//    }
//
//    /// SwifterSwift: Corner radius of view; also inspectable from Storyboard.
//    @IBInspectable var cornerRadius: CGFloat {
//        get {
//            return layer.cornerRadius
//        }
//        set {
//            layer.masksToBounds = true
//            layer.cornerRadius = abs(CGFloat(Int(newValue * 100)) / 100)
//        }
//    }
}
