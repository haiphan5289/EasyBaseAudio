//
//  ABBorder.swift
//  selfband
//
//

import UIKit

class ABBorder: UIView {
    
    struct Constant {
        static let colorBG: UIColor? = UIColor(named: "Color1")
    }

    var imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
//        let bundle = Bundle(for: ABStartIndicator.self)
//        let image = UIImage(named: "BorderLine", in: bundle, compatibleWith: nil)
        
//        imageView.frame = self.bounds
//        imageView.image = image
//        imageView.contentMode = UIView.ContentMode.scaleToFill
//        self.addSubview(imageView)
        
        self.backgroundColor = .red
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = self.bounds
    }

}
