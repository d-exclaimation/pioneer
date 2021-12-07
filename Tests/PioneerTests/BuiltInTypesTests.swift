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
    func testID() throws {
        let random = ID.random()
        XCTAssert(random.count == 10)
    }
}
