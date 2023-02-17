//  SecurityTest.swift
//
//
//  Created by d-exclaimation on 25/06/22.
//

import Graphiti
import NIOHTTP1
@testable import Pioneer
import XCTest

final class SecurityTest: XCTestCase {
    private let pioneer = try! Pioneer(
        schema: .init {
            Query {
                Field("hello", at: Resolver.hello)
            }
        },
        resolver: Resolver(),
        httpStrategy: .csrfPrevention
    )

    struct Resolver {
        func hello(_: Void, _: NoArguments) -> String { "Hello" }
    }

    /// CSRF Prevention // Protection should
    /// - Return true if protection is inactive
    /// - Return false if protection is active and request has no required headers
    /// - Return true if protection is active and request has either `Apollo-Require-Preflight` or `X-Apollo-Operation-Name`
    /// - Return true if protection is active, request has acceptable content type
    /// - Return false otherwise
    func testCsrfPreventionChecking() {
        // No required headers
        let headers = HTTPHeaders()
        let res = pioneer.csrfVulnerable(given: headers)
        XCTAssertFalse(res)

        // Has required headers and either `Apollo-Require-Preflight` or `X-Apollo-Operation-Name`
        let headers1 = HTTPHeaders([("Apollo-Require-Preflight", "True")])
        let res1 = pioneer.csrfVulnerable(given: headers1)
        XCTAssertFalse(res1)

        // Has required headers and either `Apollo-Require-Preflight` or `X-Apollo-Operation-Name`
        let headers2 = HTTPHeaders([("X-Apollo-Operation-Name", "SomeQuery")])
        let res2 = pioneer.csrfVulnerable(given: headers2)
        XCTAssertFalse(res2)

        // Has required headers and acceptable content type
        let headers3 = HTTPHeaders([("Content-Type", "application/json")])
        let res3 = pioneer.csrfVulnerable(given: headers3)
        XCTAssertFalse(res3)

        for unacceptable in ["text/plain", "application/x-www-form-urlencoded", "multipart/form-data"] {
            // Has required headers and unacceptable content type
            let headers4 = HTTPHeaders([("Content-Type", unacceptable)])
            let res4 = pioneer.csrfVulnerable(given: headers4)
            XCTAssertTrue(res4)

            // Has required headers, unacceptable content type and either `Apollo-Require-Preflight` or `X-Apollo-Operation-Name`
            let headers5 = HTTPHeaders([("Content-Type", unacceptable), ("Apollo-Require-Preflight", "True")])
            let res5 = pioneer.csrfVulnerable(given: headers5)
            XCTAssertFalse(res5)

            // Has required headers, unacceptable content type and either `Apollo-Require-Preflight` or `X-Apollo-Operation-Name`
            let headers6 = HTTPHeaders([("Content-Type", unacceptable), ("X-Apollo-Operation-Name", "SomeQuery")])
            let res6 = pioneer.csrfVulnerable(given: headers6)
            XCTAssertFalse(res6)
        }
    }
}
