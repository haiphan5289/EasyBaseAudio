//
//  UITextFieldExtensions.swift
//  SwifterSwift
//
//  Created by Omar Albeik on 8/5/16.
//  Copyright © 2016 Omar Albeik. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit

// MARK: - Enums
public extension UITextField {
    
    /// SwifterSwift: UITextField text type.
    ///
    /// - emailAddress: UITextField is used to enter email addresses.
    /// - password: UITextField is used to enter passwords.
    /// - generic: UITextField is used to enter generic text.
    enum TextType {
        case emailAddress
        case password
        case generic
    }
    
}


// MARK: - Properties
public extension UITextField {
    
    /// SwifterSwift: Set textField for common text types.
    var textType: TextType {
        get {
            if keyboardType == .emailAddress {
                return .emailAddress
            } else if isSecureTextEntry {
                return .password
            }
            return .generic
        }
        set {
            switch newValue {
            case .emailAddress:
                keyboardType = .emailAddress
                autocorrectionType = .no
                autocapitalizationType = .none
                isSecureTextEntry = false
                placeholder = "Email Address"
                
            case .password:
                keyboardType = .asciiCapable
                autocorrectionType = .no
                autocapitalizationType = .none
                isSecureTextEntry = true
                placeholder = "Password"
                
            case .generic:
                isSecureTextEntry = false
                
            }
        }
    }
    
    
    /// SwifterSwift: Check if text field is empty.
    var isEmpty: Bool {
        return text?.isEmpty == true
    }
    
    /// SwifterSwift: Return text with no spaces or new lines in beginning and end.
    var trimmedText: String? {
        return text?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// SwifterSwift: Check if textFields text is a valid email format.
    ///
    ///        textField.text = "john@doe.com"
    ///        textField.hasValidEmail -> true
    ///
    ///        textField.text = "swifterswift"
    ///        textField.hasValidEmail -> false
    ///
    var hasValidEmail: Bool {
        // http://stackoverflow.com/questions/25471114/how-to-validate-an-e-mail-address-in-swift
        return text?.range(of: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}",
                           options: String.CompareOptions.regularExpression,
                           range: nil, locale: nil) != nil
    }
    
    @IBInspectable
    /// SwifterSwift: Left view tint color.
    var leftViewTintColor: UIColor? {
        get {
            guard let iconView = leftView as? UIImageView else {
                return nil
            }
            return iconView.tintColor
        }
        set {
            guard let iconView = leftView as? UIImageView else {
                return
            }
            iconView.image = iconView.image?.withRenderingMode(.alwaysTemplate)
            iconView.tintColor = newValue
        }
    }
    
    @IBInspectable
    /// SwifterSwift: Right view tint color.
    var rightViewTintColor: UIColor? {
        get {
            guard let iconView = rightView as? UIImageView else {
                return nil
            }
            return iconView.tintColor
        }
        set {
            guard let iconView = rightView as? UIImageView else {
                return
            }
            iconView.image = iconView.image?.withRenderingMode(.alwaysTemplate)
            iconView.tintColor = newValue
        }
    }
}

// MARK: - Methods
public extension UITextField {
    
    /// SwifterSwift: Clear text.
    func clear() {
        text = ""
        attributedText = NSAttributedString(string: "")
    }
    
    /// SwifterSwift: Set placeholder text color.
    ///
    /// - Parameter color: placeholder text color.
    func setPlaceHolderTextColor(_ color: UIColor) {
        guard let holder = placeholder, !holder.isEmpty else {
            return
        }
        self.attributedPlaceholder = NSAttributedString(string: holder, attributes: [NSAttributedString.Key.foregroundColor: color])
    }
    
    /// SwifterSwift: Add padding to the left of the textfield rect.
    ///
    /// - Parameter padding: amount of padding to apply to the left of the textfield rect.
    func addPaddingLeft(_ padding: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: frame.height))
        leftView = paddingView
        leftViewMode = .always
    }
    //
    //    /// SwifterSwift: Add padding to the left of the textfield rect.
    //    ///
    //    /// - Parameters:
    //    ///   - image: left image
    //    ///   - padding: amount of padding between icon and the left of textfield
    func addPaddingLeftIcon(_ image: UIImage?, iconSize : CFloat = 15, padding: CGFloat) {
        
         let rightViewWidth : CGFloat = 30
               let customView = UIView.init(frame: CGRect.init(x: 0, y: self.frame.size.height/2 - 30/2 , width: rightViewWidth, height: rightViewWidth))
               self.leftView = customView
               let imageView = UIImageView(frame: CGRect(x: 8, y: 30/2 - 15/2, width: 15, height: 15))
               imageView.image = image
               imageView.contentMode = .scaleAspectFit
               customView.addSubview(imageView)
               self.leftViewMode = UITextField.ViewMode.always
    }
    
    /// SwifterSwift: Add padding to the left of the textfield rect.
    ///
    /// - Parameter padding: amount of padding to apply to the left of the textfield rect.
    func addPaddingRight(_ padding: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: frame.height))
        rightView = paddingView
        rightViewMode = .always
    }
    
    /// SwifterSwift: Add padding to the left of the textfield rect.
    ///
    /// - Parameters:
    ///   - image: left image
    ///   - padding: amount of padding between icon and the left of textfield
    func addPaddingRightIcon(_ image: UIImage?, iconSize : CFloat = 15, padding: CGFloat) {
        //https://stackoverflow.com/questions/58335586/uitextfield-leftview-and-rightview-overlapping-issue-ios13
        let rightViewWidth : CGFloat = 30
        let customView = UIView.init(frame: CGRect.init(x: 0, y: self.frame.size.height/2 - 30/2 , width: rightViewWidth, height: rightViewWidth))
        self.rightView = customView
        let imageView = UIImageView(frame: CGRect(x: 0, y: 30/2 - 15/2, width: 15, height: 15))
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        customView.addSubview(imageView)
        self.rightViewMode = UITextField.ViewMode.always
        
    }
    
    func addPaddingLeftRightIcon(leftImage: UIImage?, rightImage: UIImage, padding: CGFloat) {
        //        addPaddingLeftIcon(leftImage, padding: padding)
        addPaddingRightIcon(rightImage, padding: padding)
    }
    
}


#endif
