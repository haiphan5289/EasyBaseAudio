//
//  UISearchBarExtensions.swift
//  SwifterSwift
//
//  Created by Omar Albeik on 8/23/16.
//  Copyright © 2016 SwifterSwift
//

#if canImport(UIKit) && os(iOS)
import UIKit

// MARK: - Properties
public extension UISearchBar {

    /// SwifterSwift: Text field inside search bar (if applicable).
    var textField: UITextField? {
        if #available(iOS 13.0, *) {
            return self.searchTextField
        } else {
            // Fallback on earlier versions
            guard let contentView = subviews.first else { return nil }
            let textField = contentView.subviews.first(where: { $0 is UITextField }) as? UITextField
            return textField
        }
    }

    /// SwifterSwift: Text with no spaces or new lines in beginning and end (if applicable).
    var trimmedText: String? {
        return text?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

}

// MARK: - Methods
public extension UISearchBar {

    /// SwifterSwift: Clear text.
    func clear() {
        text = ""
    }

}

#endif
