//
//  Collection+Extension.swift
//  Audio
//
//  Created by haiphan on 5/19/21.
//

import Foundation


public extension RangeReplaceableCollection where Indices: Equatable {
    mutating func rearrange(from: Index, to: Index) {
        precondition(from != to && indices.contains(from) && indices.contains(to), "invalid indices")
        insert(remove(at: from), at: to)
    }
}
