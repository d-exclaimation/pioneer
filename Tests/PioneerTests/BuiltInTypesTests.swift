//
//  BuiltInTypesTests.swift
//  Pioneer
//
//  Created by d-exclaimation on 2:26 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import XCTest
@testable import Pioneer

final class BuiltInTypesTests: XCTestCase {
    /// Test ID Randomised features
    func testID() throws {
        let random = ID.random()
        XCTAssert(random.count == 10)
    }
    
    /// Test ID JSON Encoding
    func testIDJSON() throws {
        let myID: ID = "123"
        
        let data = try JSONEncoder().encode(myID)
    
        guard let result = String(data: data, encoding: .utf8) else {
            return XCTFail("Cannot create string from JSON Data")
        }
        
        XCTAssert(result == "\"123\"")
    }
}
