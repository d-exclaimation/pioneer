//
//  Data+Json.swift
//  Pioneer
//
//  Created by d-exclaimation on 10:55 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation

extension Data {
    func to<T: Decodable>(_ type: T.Type) -> T? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(T.self, from: self)
    }
}