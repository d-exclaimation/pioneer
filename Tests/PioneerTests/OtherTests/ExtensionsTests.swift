//
//  ExtensionsTests.swift
//  Pioneer
//
//  Created by d-exclaimation on 2:16 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import enum GraphQL.Map
import OrderedCollections
@testable import Pioneer
import XCTest

final class ExtensionsTests: XCTestCase {

    /// Pipe back Future to an actor
    /// 1. Should not fulfill under 1 second
    /// 2. Should fulfill by the Actor after the delay
    func testActorAndNIOFuture() async {
        actor Tester {
            func call(expect: Task<XCTestExpectation, Error>) {
                pipeToSelf(future: expect) { sink, res in
                    guard case let .success(ex) = res else { return }
                    ex.fulfill()
                }
            }
        }

        let expectation = XCTestExpectation()
        let tester = Tester()


        await tester.call(expect: .init {
            try? await Task.sleep(nanoseconds: 1000 * 1000 * 1000)
            return expectation
        })

        wait(for: [expectation], timeout: 2)
    }

    /// JSON String to Structure
    /// 1. Should be able to parse all fields if given
    /// 2. Should be able to infer Optional if not given
    func testDataJSONDecoder() {
        struct A: Decodable {
            var id: String?
        }

        // Should be able to parse all fields if given
        let json = "{ \"id\": null }"
        guard let res = json.data(using: .utf8)?.to(A.self) else {
            return XCTFail("Un-decodable JSON")
        }
        XCTAssert(res.id == nil)


        // Should be able to infer Optional if not given
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
        var dict = [String: Int]()

        // Should not call callback if found
        dict["a"] = 1
        let a = dict.getOrElse("a", or: {
            XCTFail("Should not call")
            return Int.random()
        })
        XCTAssert(a == 1)

        // Should call callback if not found
        let exp = XCTestExpectation(description: "Should call")
        let _ = dict.getOrElse("b", or: {
            exp.fulfill()
            return 0
        })
        wait(for: [exp], timeout: 1)
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
