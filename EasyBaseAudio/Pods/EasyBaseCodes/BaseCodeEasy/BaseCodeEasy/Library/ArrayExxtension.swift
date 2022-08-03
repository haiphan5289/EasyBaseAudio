//
//  ArrayExxtension.swift
//  Note
//
//  Created by haiphan on 06/10/2021.
//

import Foundation

public extension Array {
    
    func hasIndex(index: Int) -> Int? {
        for i in 0...self.count - 1 {
            if index == i {
                return i
            }
        }
        return nil
    }
}
