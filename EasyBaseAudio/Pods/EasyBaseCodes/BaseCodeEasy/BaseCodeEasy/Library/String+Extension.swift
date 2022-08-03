//
//  String+Extension.swift
//  Kiple
//
//  Created by ThanhPham on 8/4/17.
//  Copyright © 2017 com.futurify.vn. All rights reserved.
//

import Foundation
import UIKit
public extension String {
    
    func toCNPrice() -> String {
        return "￥\(self)"
    }
    
    func matchingStrings(regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = self as NSString
            let results = regex.matches(in: self,
                                        options: [], range: NSMakeRange(0, nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    func isValidRegex(_ regex : String) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        let result = predicate.evaluate(with: self) as Bool
        return result
    }
    
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return boundingBox.height
    }
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return boundingBox.width
    }
    var westernArabicNumeralsOnly: String {
        let pattern = UnicodeScalar("0")..."9"
        return String(unicodeScalars
            .flatMap { pattern ~= $0 ? Character($0) : nil })
    }
    
    public func toPhoneNumber() -> String {
        return self.replacingOccurrences(of: "(\\d{3})(\\d{3})(\\d+)", with: "$1-$2-$3", options: .regularExpression, range: nil)
    }
    
    
    func validateEmail() -> Bool {
        let emailRegEx = "^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }
    
    func validatePhone() -> Bool {
           let PHONE_REGEX = "^\\d{3}-\\d{3}-\\d{4}$"
           let emailTest = NSPredicate(format:"SELF MATCHES %@", PHONE_REGEX)
           return emailTest.evaluate(with: self)
       }
    
    func searchLocation(searchText: String) -> NSRange? {
        do {
            let regEx = try NSRegularExpression(pattern: searchText, options: NSRegularExpression.Options.ignoreMetacharacters)
            
            let matchesRanges = regEx.matches(in: self, options: [], range: NSMakeRange(0, self.count)).map { $0.range }
            
            return matchesRanges.first
        } catch {
            print(error)
        }
        return nil
    }
    
    func cutString(range: NSRange) -> String? {
        guard hasRange(NSRange(location: range.location + 1, length: range.length)) else {
            return nil
        }
        let start = self.index(self.startIndex, offsetBy: range.location + 1)
        let end = self.index(self.endIndex, offsetBy: 0)
        let range = start..<end
        let mySubstring = self[range]
        return String(mySubstring)
    }
    
    func hasRange(_ range: NSRange) -> Bool {
        return Range(range, in: self) != nil
    }
}

public extension NSMutableAttributedString {
    
    public func color(string : String, color : UIColor)  -> Self {
        let attributedString = NSAttributedString.init(string: string, attributes: [NSAttributedString.Key.foregroundColor : color])
        self.append(attributedString)
        return self
    }
    
    public func backgroundColorColor(string : String, color : UIColor)  -> Self {
        let attributedString = NSAttributedString.init(string: string, attributes: [NSAttributedString.Key.backgroundColor : color])
        self.append(attributedString)
        return self
    }
    
    func addFont(string : String, font : UIFont){
        
        let currentString = NSString.init(string: self.string)
        self.addAttribute(NSAttributedString.Key.font, value: font, range: currentString.range(of: string))
    }
    
    func addColor(string : String, color : UIColor){
        let currentString = NSString.init(string: self.string)
        self.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: currentString.range(of: string))
    }
    
    func addBackgroundColor(string : String, color : UIColor){
        let currentString = NSString.init(string: self.string)
        self.addAttribute(NSAttributedString.Key.backgroundColor, value: color, range: currentString.range(of: string))
    }
    
    func addUnderline(string : String){
        let currentString = NSString.init(string: self.string)
        self.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: currentString.range(of: string))
    }
    func addStrikethroughStyle(string : String){
        let currentString = NSString.init(string: self.string)
        self.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: currentString.range(of: string))
    }
}

public extension NSAttributedString {
    func height(withConstrainedWidth width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return boundingBox.height
    }
    
    func width(withConstrainedHeight height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return boundingBox.width
    }
    
    
}

public extension Data {
    var html2AttributedString: NSAttributedString? {
        do {
            return try NSAttributedString(data: self, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            print("error:", error)
            return  nil
        }
    }
    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
}

public extension String {
    var html2AttributedString: NSAttributedString? {
        return Data(utf8).html2AttributedString
    }
    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
}
