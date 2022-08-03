//
//  SKProductModel.swift
//  BaseCodeEasy
//
//  Created by haiphan on 07/05/2022.
//////
//

import Foundation

public struct SKProductModel {
    public let productID: String
    public let price: NSDecimalNumber
    public init(productID: String, price: NSDecimalNumber) {
        self.productID = productID
        self.price = price
    }
    
    public func getTextPrice() -> String {
        return "$\(self.price.roundTo())"
    }
}
