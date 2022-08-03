//
//  ViewExtension.swift
//  Dayshee
//
//  Created by haiphan on 11/1/20.
//  Copyright © 2020 ThanhPham. All rights reserved.
//

import UIKit

public extension UIView {
    static var nib: UINib? {
        let bundle = Bundle(for: self)
        let name = "\(self)"
        guard bundle.path(forResource: name, ofType: "nib") != nil else {
            return nil
        }
        return UINib(nibName: name, bundle: nil)
    }
    
    
    static var identifier: String {
        return "\(self)"
    }
}

public protocol LoadXibProtocol {}
public extension LoadXibProtocol where Self: UIView {
    static func loadXib() -> Self {
        let bundle = Bundle(for: self)
        let name = "\(self)"
        guard let view = UINib(nibName: name, bundle: bundle).instantiate(withOwner: nil, options: nil).first as? Self else {
            fatalError("error xib \(name)")
        }
        return view
    }
}
extension UIView: LoadXibProtocol {}
public extension UIView {
    func applyShadowAndRadius(sizeX: CGFloat, sizeY: CGFloat,shadowRadius: CGFloat, shadowColor: UIColor) {
        self.backgroundColor = UIColor.clear
        self.layer.shadowColor = shadowColor.cgColor
        self.layer.shadowOffset = CGSize(width: sizeX, height: sizeY) //x,
        self.layer.shadowOpacity = 0.7
        self.layer.shadowRadius = shadowRadius //blur
        
        // add the border to subview
        //        let borderView = UIView()
        //        borderView.frame = self.bounds
        //        borderView.layer.cornerRadius = 10
        //
        //        borderView.layer.borderColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.16)
        //        borderView.layer.borderWidth = 0.1
        //        borderView.layer.masksToBounds = true
        //        self.addSubview(borderView)
    }
    
//    @IBInspectable var borderColor: UIColor? {
//        get {
//            guard let color = layer.borderColor else { return nil }
//            return UIColor(cgColor: color)
//        }
//        set {
//            guard let color = newValue else {
//                layer.borderColor = nil
//                return
//            }
//            // Fix React-Native conflict issue
//            guard String(describing: type(of: color)) != "__NSCFType" else { return }
//            layer.borderColor = color.cgColor
//        }
//    }

    /// SwifterSwift: Border width of view; also inspectable from Storyboard.
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    /// SwifterSwift: Corner radius of view; also inspectable from Storyboard.
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.masksToBounds = true
            layer.cornerRadius = abs(CGFloat(Int(newValue * 100)) / 100)
        }
    }
}
public extension UIView {
//    func shake() {
//        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
//        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
//        animation.duration = 0.6
//        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
//        layer.add(animation, forKey: "shake")
//    }
    func shake(){
            let animation = CABasicAnimation(keyPath: "position")
            animation.duration = 0.07
            animation.repeatCount = 3
            animation.autoreverses = true
            animation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x, y: self.center.y - 5))
            animation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x, y: self.center.y + 5))
            self.layer.add(animation, forKey: "position")
        }
}
public extension UIView {
    
    // Export pdf from Save pdf in drectory and return pdf file path
    func exportAsPdfFromView(linkFolder: URL) -> String {
        
        let pdfPageFrame = self.bounds
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pdfPageFrame, nil)
        UIGraphicsBeginPDFPageWithInfo(pdfPageFrame, nil)
        guard let pdfContext = UIGraphicsGetCurrentContext() else { return "" }
        self.layer.render(in: pdfContext)
        UIGraphicsEndPDFContext()
        return self.saveViewPdf(data: pdfData, linkFolder: linkFolder)
        
    }
    
    // Save pdf file in document directory
    func saveViewPdf(data: NSMutableData, linkFolder: URL) -> String {
        let pdfPath = linkFolder
        if data.write(to: pdfPath, atomically: true) {
            return pdfPath.path
        } else {
            return ""
        }
    }
}
