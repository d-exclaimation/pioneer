//
//  Dictionary+SafeOperation.swift
//  Pioneer
//
//  Created by d-exclaimation on 11:38 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation

extension Dictionary {
    /// Method for mutating value of a Dictionary instead of using a assignment.
    mutating func update(_ key: Key, with value: Value) {
        self[key] = value
    }

    /// Method for mutating value of a Dictionary instead of using a assignment.
    mutating func delete(_ key: Key) {
        removeValue(forKey: key)
    }

    /// Method for mutating value of a Dictionary instead of using a assignment.
    func getOrElse(_ key: Key, or fallback: () -> Value) -> Value {
        self[key] ?? fallback()
    }

    func has(_ key: Key) -> Bool {
        guard let _ = self[key] else { return false }
        return true
    }
}