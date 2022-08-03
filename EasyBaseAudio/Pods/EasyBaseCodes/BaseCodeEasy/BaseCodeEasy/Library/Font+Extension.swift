//
//  Font+Extension.swift
//  CanCook
//
//  Created by haiphan on 2/4/21.
//

import UIKit

public extension UIFont {
    class func droidSans(size: CGFloat) -> UIFont {
        return UIFont(name: "DroidSans", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    class func googleSansRegular(size: CGFloat) -> UIFont {
        return UIFont(name: "GoogleSans-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    class func googleSansMedium(size: CGFloat) -> UIFont {
        return UIFont(name: "GoogleSans-Medium", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
}
