//
//  ExtensionsTests.swift
//  Pioneer
//
//  Created by d-exclaimation on 2:16 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import XCTest
import OrderedCollections
import NIO
@testable import Pioneer

final class ExtensionsTests: XCTestCase {
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 4)

    /// Tester Actor
    private actor Tester {
        enum Act {
            case call(expect: EventLoopFuture<XCTestExpectation>)
            case outcome(expect: XCTestExpectation)
            case none
        }
        
        func call(expect: EventLoopFuture<XCTestExpectation>) {
            pipeToSelf(future: expect) { sink, res in
                guard case .success(let ex) = res else { return }
                await sink.outcome(expect: ex)
            }
        }
        
        func outcome(expect: XCTestExpectation) {
            expect.fulfill()
        }
    }

    /// Pipe back Future to an actor
    /// 1. Should not fulfill under 1 second
    /// 2. Should fulfill by the Actor after the delay
    func testActorAndNIOFuture() async {
        let expectation = XCTestExpectation()
        let tester = Tester()
        let future = eventLoopGroup.task { () async -> XCTestExpectation in
            try? await Task.sleep(nanoseconds: 1000 * 1000 * 1000)
            return expectation
        }
        await tester.call(expect: future)

        wait(for: [expectation], timeout: 2)
    }

    /// Test Structure
    struct A: Decodable {
        var id: String?
    }
    
    /// JSON String to Structure
    /// 1. Should be able to parse all fields if given
    /// 2. Should be able to infer Optional if not given
    func testDataJSONDecoder() {
        let json = "{ \"id\": null }"
        guard let res = json.data(using: .utf8)?.to(A.self) else {
            return XCTFail("Un-decodable JSON")
        }
        XCTAssert(res.id == nil)

        let json2 = "{}"
        guard let res2 = json2.data(using: .utf8)?.to(A.self) else {
            return XCTFail("Un-decodable JSON")
        }
        XCTAssert(res2.id == nil)
    }

    /// Dictionary Mutating method operations
    /// 1. Should not call callback if found
    /// 2. Should call callback if not found
    func testDictionaryOperation() {
        var isAllowed = false
        var dict = [String:Int]()
        func produce() -> Int {
            XCTAssert(isAllowed)
            return Int.random()
        }

        dict["a"] = 1
        let a = dict.getOrElse("a", or: produce)
        XCTAssert(a == 1)
        isAllowed.toggle()
        let _ = dict.getOrElse("b", or: produce)
    }

    /// Bridging between two dictionaries
    /// 1. Should remain all key value pairs when converting
    func testOrderedDictionaryCompat() {
        var ordered = OrderedDictionary<String, Int>()
        ordered["1"] = 1
        ordered["2"] = 2

        let unordered = ordered.unordered()
        guard let res1 = unordered["1"], let res2 = unordered["2"] else {
            return XCTFail()
        }
        XCTAssert(res1 == 1 && res2 == 2)
    }
}
