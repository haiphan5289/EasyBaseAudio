//
//  UITextField_Extension.swift
//  MVVM_2020
//
//  Created by Admin on 10/8/20.
//  Copyright © 2020 ThanhPham. All rights reserved.
//

import Foundation
import UIKit
public class TextField: UITextField {

    let padding = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 5)

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}
