//
//  Encode+Extension.swift
//  AnimeDraw
//
//  Created by paxcreation on 12/14/20.
//

import UIKit
import SwiftyJSON

public extension Encodable {
    public func toData() throws -> Data {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        return data
    }
    public func toJSON() throws -> JSON {
        let data = try toData()
        let value = try JSONSerialization.jsonObject(with: data, options: [])
        guard let json = value as? JSON else {
              throw NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: [NSLocalizedDescriptionKey : "Failed make json!!!!"])
        }
        return json
    }
}

