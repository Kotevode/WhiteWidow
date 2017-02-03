//
//  WildcardsTest.swift
//  WhiteWidow
//
//  Created by Mark on 02.02.17.
//
//

import XCTest

class WildcardsTest: XCTestCase {

    func testCanSatisfyWildcard() {
        
        let rootURL = URL(string: "http://eda.ru/some/")!
        
        var wildcard = URLWildcard(url: URL(string: "/*", relativeTo: rootURL)!)
        var url = URL(string: "/recepty", relativeTo: rootURL)!
        XCTAssertTrue(url ~= wildcard, "This should match")
        url = URL(string: "/recepty/huita", relativeTo: rootURL)!
        XCTAssertTrue(url ~= wildcard, "This should match")
        url = URL(string: "http://google.com", relativeTo: rootURL)!
        XCTAssertFalse(url ~= wildcard, "This should not match")
        
        wildcard = URLWildcard(url: URL(string: "/*/index.html", relativeTo: rootURL)!)
        url = URL(string: "/recepty/index.html", relativeTo: rootURL)!
        XCTAssertTrue(url ~= wildcard, "This should match")
        url = URL(string: "/recepty/huita/index.html", relativeTo: rootURL)!
        XCTAssertTrue(url ~= wildcard, "This should match")
        url = URL(string: "http://google.com", relativeTo: rootURL)!
        XCTAssertFalse(url ~= wildcard, "This should not match")
    
        wildcard = URLWildcard(url: URL(string: "/", relativeTo: rootURL)!)
        url = URL(string: "/recepty", relativeTo: rootURL)!
        XCTAssertFalse(url ~= wildcard, "This should not match")
        url = URL(string: "/recepty/huita", relativeTo: rootURL)!
        XCTAssertFalse(url ~= wildcard, "This should not match")
        url = URL(string: "http://google.com", relativeTo: rootURL)!
        XCTAssertFalse(url ~= wildcard, "This should not match")
        
        wildcard = URLWildcard(url: URL(string: "/recepty/", relativeTo: rootURL)!)
        url = URL(string: "/recepty", relativeTo: rootURL)!
        XCTAssertTrue(url ~= wildcard, "This should match")
        url = URL(string: "/recepty/huita", relativeTo: rootURL)!
        XCTAssertFalse(url ~= wildcard, "This should not match")
        url = URL(string: "http://google.com", relativeTo: rootURL)!
        XCTAssertFalse(url ~= wildcard, "This should not match")
        
        wildcard = URLWildcard(url: URL(string: "/recepty/*", relativeTo: rootURL)!)
        url = URL(string: "/recepty", relativeTo: rootURL)!
        XCTAssertTrue(url ~= wildcard, "This should match")
        url = URL(string: "/recepty/huita", relativeTo: rootURL)!
        XCTAssertTrue(url ~= wildcard, "This should match")
        url = URL(string: "http://google.com", relativeTo: rootURL)!
        XCTAssertFalse(url ~= wildcard, "This should not match")
        
        wildcard = URLWildcard(url: URL(string: "../recepty/*", relativeTo: rootURL)!)
        url = URL(string: "http://eda.ru/recepty")!
        XCTAssertTrue(url ~= wildcard, "This should match")
        
    }

}
