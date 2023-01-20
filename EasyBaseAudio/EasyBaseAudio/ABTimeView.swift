//
//  ABTimeView.swift
//  Pods
//
//  Created by Oscar J. Irun on 12/12/16.
//
//

import UIKit

open class ABTimeView: UIView {

    let space: CGFloat = 8.0
    
    public var timeLabel       = UILabel()
    public var backgroundView  = UIView() {
        willSet(newBackgroundView){
            self.backgroundView.removeFromSuperview()
        }
        didSet {
            self.frame = CGRect(x: 0,
                                y: -backgroundView.frame.height - space,
                                width: backgroundView.frame.width,
                                height: backgroundView.frame.height)
            
            self.addSubview(backgroundView)
            self.sendSubviewToBack(backgroundView)
        }
    }
    
    public var marginTop: CGFloat       = 5.0
    public var marginBottom: CGFloat    = 5.0
    public var marginLeft: CGFloat      = 5.0
    public var marginRight: CGFloat     = 5.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public init(size: CGSize, position: Int){
        let frame = CGRect(x: 0,
                           y: -size.height - space,
                           width: size.width,
                           height: size.height)
        super.init(frame: frame)
        
        // Add Background View
        self.backgroundView.frame = self.bounds
        self.backgroundView.backgroundColor = .clear
        self.addSubview(self.backgroundView)
        
        // Add time label
        self.timeLabel = UILabel()
        self.timeLabel.textAlignment = .center
        self.timeLabel.font = UIFont.systemFont(ofSize: 11)
        self.timeLabel.textColor = UIColor(named: "white")
        self.addSubview(self.timeLabel)

    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundView.frame = self.bounds
        self.timeLabel.frame = CGRect(x: 0,
                                      y: 0,
                                      width: 40,
                                      height: 13)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
extension CGFloat {
    func subtracting(_ value: CGFloat) -> CGFloat {
        return self - value
    }
}
