//
//  UIApplication+Extension.swift
//  Dayshee
//
//  Created by paxcreation on 12/23/20.
//  Copyright © 2020 ThanhPham. All rights reserved.
//

import UIKit

public extension UIApplication {
    class var statusBarBackgroundColor: UIColor? {
        get {
            return (shared.value(forKey: "statusBar") as? UIView)?.backgroundColor
        } set {
            (shared.value(forKey: "statusBar") as? UIView)?.backgroundColor = newValue
        }
    }
}
