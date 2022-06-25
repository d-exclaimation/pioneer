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
        resolver: Resolver()
    )
    
    struct Resolver {
        func hello(_: Void, _: NoArguments) -> String { "Hello" }
    }
    
    /// CSRF Prevention // Protection should
    /// - Return false if protection is inactive
    /// - Return false if protection is active and request has no required headers
    /// - Return true if protection is active and request has either `Apollo-Require-Preflight` or `X-Apollo-Operation-Name`
    /// - Return false if protection is active, request has unacceptable content type, and no allowed header
    /// - Return true if protection is active, request has acceptable content type
    func testCsrfPreventionChecking() {
        let req = Request(application: application, headers: .init([]), on: application.eventLoopGroup.next())
        let res = pioneer.isCSRFProtected(isActive: false, on: req)
        XCTAssertFalse(res)
        
        let req0 = Request(application: application, headers: .init([]), on: application.eventLoopGroup.next())
        let res0 = pioneer.isCSRFProtected(on: req0)
        XCTAssertFalse(res0)
        
        let req1 = Request(application: application, headers: .init([("Apollo-Require-Preflight", "True")]), on: application.eventLoopGroup.next())
        let res1 = pioneer.isCSRFProtected(on: req1)
        XCTAssertTrue(res1)
        
        let req2 = Request(application: application, headers: .init([("X-Apollo-Operation-Name", "SomeQuery")]), on: application.eventLoopGroup.next())
        let res2 = pioneer.isCSRFProtected(on: req2)
        XCTAssertTrue(res2)
        
        let req3 = Request(application: application, method: .POST,  headers: .init([("Content-Type", "application/json")]), on: application.eventLoopGroup.next())
        let res3 = pioneer.isCSRFProtected(on: req3)
        XCTAssertTrue(res3)
        
        for unacceptable in ["text/plain", "application/x-www-form-urlencoded", "multipart/form-data"] {
            let req4 = Request(
                application: application,
                method: .POST,
                headers: .init([("Content-Type", unacceptable)]),
                on: application.eventLoopGroup.next()
            )
            let res4 = pioneer.isCSRFProtected(on: req4)
            XCTAssertFalse(res4)
            
            let req5 = Request(
                application: application,
                method: .POST,
                headers: .init([("Content-Type", unacceptable), ("Apollo-Require-Preflight", "True")]),
                on: application.eventLoopGroup.next()
            )
            let res5 = pioneer.isCSRFProtected(on: req5)
            XCTAssertTrue(res5)
            
            let req6 = Request(
                application: application,
                method: .POST,
                headers: .init([("Content-Type", unacceptable), ("X-Apollo-Operation-Name", "SomeQuery")]),
                on: application.eventLoopGroup.next()
            )
            let res6 = pioneer.isCSRFProtected(on: req6)
            XCTAssertTrue(res6)
        }
    }
}
