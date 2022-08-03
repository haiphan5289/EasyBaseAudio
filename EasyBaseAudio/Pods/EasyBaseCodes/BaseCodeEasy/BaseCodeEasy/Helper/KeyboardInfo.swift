//
//  KeyboardInfo.swift
//  Dayshee
//
//  Created by haiphan on 11/12/20.
//  Copyright © 2020 ThanhPham. All rights reserved.
//
//Make

import UIKit

public struct KeyboardInfo {
       /// Struct's public properties.
       public let duration: TimeInterval
       public let height: CGFloat
       public let hidden: Bool

       /// Struct's constructors.
       public init?(_ notification: Notification) {
           guard let userInfo = notification.userInfo else {
               return nil
           }

           duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0
           hidden = (notification.name == UIResponder.keyboardWillHideNotification)
           height = hidden ? 0 : ((userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height ?? 0)
       }

       // MARK: Struct's public methods
       public func animate(view: UIView?) {
           let transfrom = CGAffineTransform(translationX: 0, y: -height)

           UIView.animate(withDuration: duration) {
               /* Condition validation: check if it is scrollview, then we only need to change inset, otherwise we apply transform */
               guard let scrollView = view as? UIScrollView else {
                   view?.transform = transfrom
                   return
               }
               scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.height, right: 0)
           }
       }
   }
