//
//  OrderedDictionary+Dictionary.swift
//  Pioneer
//
//  Created by d-exclaimation on 4:33 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import OrderedCollections

extension OrderedDictionary {
    func unordered() -> [Key: Value] {
        var res = [Key:Value]()
        forEach { (key, val) in
            res[key] = val
        }
        return res
    }
}