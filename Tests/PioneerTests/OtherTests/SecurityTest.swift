//  SecurityTest.swift
//  
//
//  Created by d-exclaimation on 25/06/22.
//

import Foundation
import Vapor
import XCTest
import Graphiti
@testable import Pioneer

final class SecurityTest: XCTestCase {
    private let application = Application(.testing)
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
        let req = Request(application: application, headers: .init([]), on: application.eventLoopGroup.next())
        let res = pioneer.csrfVunerable(given: req.headers)
        XCTAssertFalse(res)
        
        let req1 = Request(application: application, headers: .init([("Apollo-Require-Preflight", "True")]), on: application.eventLoopGroup.next())
        let res1 = pioneer.csrfVunerable(given: req1.headers)
        XCTAssertFalse(res1)
        
        let req2 = Request(application: application, headers: .init([("X-Apollo-Operation-Name", "SomeQuery")]), on: application.eventLoopGroup.next())
        let res2 = pioneer.csrfVunerable(given: req2.headers)
        XCTAssertFalse(res2)
        
        let req3 = Request(application: application, method: .POST,  headers: .init([("Content-Type", "application/json")]), on: application.eventLoopGroup.next())
        let res3 = pioneer.csrfVunerable(given: req3.headers)
        XCTAssertFalse(res3)
        
        for unacceptable in ["text/plain", "application/x-www-form-urlencoded", "multipart/form-data"] {
            let req4 = Request(
                application: application,
                method: .POST,
                headers: .init([("Content-Type", unacceptable)]),
                on: application.eventLoopGroup.next()
            )
            let res4 = pioneer.csrfVunerable(given: req4.headers)
            XCTAssertTrue(res4)
            
            let req5 = Request(
                application: application,
                method: .POST,
                headers: .init([("Content-Type", unacceptable), ("Apollo-Require-Preflight", "True")]),
                on: application.eventLoopGroup.next()
            )
            let res5 = pioneer.csrfVunerable(given: req5.headers)
            XCTAssertFalse(res5)
            
            let req6 = Request(
                application: application,
                method: .POST,
                headers: .init([("Content-Type", unacceptable), ("X-Apollo-Operation-Name", "SomeQuery")]),
                on: application.eventLoopGroup.next()
            )
            let res6 = pioneer.csrfVunerable(given: req6.headers)
            XCTAssertFalse(res6)
        }
    }
}
