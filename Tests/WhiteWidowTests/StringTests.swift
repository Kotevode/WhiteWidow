//
//  StringTests.swift
//  WhiteWidow
//
//  Created by Mark on 09.02.17.
//
//

import XCTest
@testable import WhiteWidow

class StringTests: XCTestCase {

    func testCanTrimFragment(){
        let str = "abc/def?a=1#frag"
        XCTAssertEqual(str.deletingFragment, "abc/def?a=1")
        let str2 = "abc/def#frag"
        XCTAssertEqual(str2.deletingFragment, "abc/def")
    }
    
}
