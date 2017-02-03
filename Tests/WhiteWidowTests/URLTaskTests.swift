//
//  URLTaskTests.swift
//  WhiteWidow
//
//  Created by ПК-1 on 03.02.17.
//
//

import XCTest
import Fluent
import FluentPostgreSQL
@testable import WhiteWidow

class URLTaskTests: XCTestCase {
    
    var database: Fluent.Database!
    
    override func setUp() {
        super.setUp()
        let driver = FluentPostgreSQL.PostgreSQLDriver(host: "localhost",
                                                   port: 5432,
                                                   dbname: "ww_test",
                                                   user: "ww_test",
                                                   password: "qwerty")
        database = Fluent.Database(driver)
        guard try! database.hasPrepared(URLTask.self) else {
            try! database.prepare(URLTask.self)
            return
        }
        
    }
    
    override func tearDown() {
        try! URLTask.revert(database)
        try! database.delete("fluent")
        super.tearDown()
    }
    
    func testCanCreateURLTasks() {
        
        var task = URLTask(url: URL(string: "http://google.com")!,
                           updateInterval: 0.0)
        try! task.save()
        XCTAssertEqual(try! URLTask.all().count, 1)
    }
    
}
