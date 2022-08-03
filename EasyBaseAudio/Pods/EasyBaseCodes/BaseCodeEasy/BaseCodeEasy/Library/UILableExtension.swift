//
//  UILableExtension.swift
//  WoodPeckers
//
//  Created by Macbook on 6/8/20.
//  Copyright © 2020 ThanhPham. All rights reserved.
//

import UIKit
public extension UILabel {
    func blink() {
        self.alpha = 0.0;
        UIView.animate(withDuration: 0.8, //Time duration you want,
            delay: 0.0,
            options: [.curveEaseInOut, .autoreverse, .repeat],
            animations: { [weak self] in self?.alpha = 1.0 },
            completion: { [weak self] _ in self?.alpha = 0.0 })
    }
}
