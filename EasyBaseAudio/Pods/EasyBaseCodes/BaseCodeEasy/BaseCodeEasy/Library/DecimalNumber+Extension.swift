//
//  DecimalNumber+Extension.swift
//  ManageFiles
//
//  Created by haiphan on 21/02/2022.
//

import Foundation

public extension NSDecimalNumber {
     func roundTo() -> String {
        let value = Double(truncating: self)
        return String(format:"%.2f", value)
    }
}
