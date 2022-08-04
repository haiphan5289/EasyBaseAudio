//
//  StringExtension.swift
//  Dayshee
//
//  Created by paxcreation on 11/2/20.
//  Copyright © 2020 ThanhPham. All rights reserved.
//

import UIKit

public extension String {
    var isUpdateContain: Bool {
        let upperCase = CharacterSet.uppercaseLetters
        for i in self.unicodeScalars {
            if upperCase.contains(i) {
                return true
            }
        }
        return false
    }
//    var isNumeric: Bool {
//            guard self.count > 0 else { return false }
//            let nums: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
//            return Set(self).isSubset(of: nums)
//    }
    var isHaveNumber: Bool {
        let decimalCharacters = CharacterSet.decimalDigits
        let decimalRange = self.rangeOfCharacter(from: decimalCharacters)
        if decimalRange != nil {
            return true
        }
        return false
    }
    func getTextSize(fontSize: CGFloat, width: CGFloat) -> CGRect {
        let size = CGSize(width: width, height: 50)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: self).boundingRect(with: size, options: options,
                                                   attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: fontSize)],
                                                   context: nil)
    }
    func getTextSizeNoteView(fontSize: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
        let size = CGSize(width: width, height: height)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: self).boundingRect(with: size, options: options,
                                                   attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: fontSize)],
                                                   context: nil)
    }
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
    
//    func toDate(from format: String) -> Date? {
//        let dateFormatter = DateFormatter()
//        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
//        dateFormatter.dateFormat = "\(format)"
//        let date = dateFormatter.date(from:self)
//        return date
//    }
//    func toCovertDate(format: String) -> Date? {
//        let dateFormatter = DateFormatter()
////        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
////        dateFormatter.dateFormat = format
//        dateFormatter.dateFormat = format
//            dateFormatter.timeZone = TimeZone.current
//            dateFormatter.locale = Locale.current
//        let date = dateFormatter.date(from:"2020-01-10")
//        return date
//    }
}
public extension UIImageView {
    func applyshadowWithCorner(containerView : UIView, cornerRadious : CGFloat){
        containerView.clipsToBounds = false
        containerView.layer.shadowColor = UIColor.white.cgColor
        containerView.layer.shadowOpacity = 1
        containerView.layer.shadowOffset = CGSize.zero
        containerView.layer.shadowRadius = 10
        containerView.layer.cornerRadius = cornerRadious
        containerView.layer.shadowPath = UIBezierPath(roundedRect: containerView.bounds, cornerRadius: cornerRadious).cgPath
        self.clipsToBounds = true
        self.layer.cornerRadius = cornerRadious
    }

}

public extension String {
    
    enum FormatDate: String, CaseIterable {
        case yyyyMMddHHmmss = "yyyy-MM-dd HH:mm:ss"
        case HHmmssddMMyyyy = "HH:mm:ss dd/MM/yyyy"
        case HHmmddMMyyyy = "HH:mm dd MMM, yyyy"
        case yyyyMMdd = "yyyy-MM-dd"
        case HHmm = "HH:mm"
        case HHmmss = "HH:mm:ss"
        case HHmma = "HH:mm a"
        case MMddyyyy = "MM/dd/yyyy"
        case ddMMyyyy = "dd/MM/yyyy"
        case ddMMyyyyHHmmss = "dd/MM/yyyy HH:mm:ss"
        case MMddyyyyHHmmss = "MM/dd/yyyy HH:mm:ss"
        case yyyyMMđHHmm = "yyyyMMddHHmm"
        case HHmmEEEEddMMyyyy = "HH:mm, EEEE dd/MM/yyyy"
        case EEddThangMM = "E, dd %@ MM "
    }
    
    func convertToDate() -> Date? {
        var date: Date?
        FormatDate.allCases.forEach { format in
            if date != nil {
                return
            }
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale.current
            dateFormatter.dateFormat = format.rawValue
            date = dateFormatter.date(from: self)
            
        }
        return date
    }
}

public extension Date {
    private static let formatDateDefault = DateFormatter()
    func covertToString(format: String.FormatDate) -> String {
        Date.formatDateDefault.locale = .current
        Date.formatDateDefault.dateFormat = format.rawValue
        let result = Date.formatDateDefault.string(from: self)
        return result
    }
    
}

public extension Date {
    func covertToDate(format: String.FormatDate) -> Date? {
        Date.formatDateDefault.locale = .current
        Date.formatDateDefault.timeZone = TimeZone(abbreviation: "UTC+9")
        Date.formatDateDefault.locale = Locale(identifier: "en_US_POSIX")
        Date.formatDateDefault.dateFormat = format.rawValue
        let result = Date.formatDateDefault.date(from: self.covertToString(format: format))
        return result
    }
    
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }

    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
}

public extension String {
    
    func converToImage() -> UIImage? {
        return UIImage(named: self)
    }
    
    func covertToColor() -> UIColor? {
        return UIColor(hexString: self)
    }
    
}
