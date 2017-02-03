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
    
    func testCanSelectExpired() {
        var t1 = URLTask(url: URL(string: "http://google.com")!, updateInterval: 30*60)
        var t2 = URLTask(url: URL(string: "yahoo.com")!, updateInterval: 100*60)
        var t3 = URLTask(url: URL(string: "yandex.com")!, updateInterval: 200*60)
        t1.lastUpdate = Date().addingTimeInterval(-150*60)
        t2.lastUpdate = Date().addingTimeInterval(-150*60)
        t3.lastUpdate = Date().addingTimeInterval(-150*60)
        try! t1.save()
        try! t2.save()
        try! t3.save()
        
        let expired = try! URLTask.expired()
        
        XCTAssertEqual(expired.count, 2)
    }
    
    func testCanMakeHierarchy() {
        var t1 = URLTask(url: URL(string: "http://google.com")!, updateInterval: 30*60)
        var t2 = URLTask(url: URL(string: "yahoo.com")!, updateInterval: 100*60)
        try! t1.save()
        t2.foundIn = t1.id
        try! t2.save()
        
        let child = try! t1.childrenTasks().first()!
        XCTAssertEqual(child.url.absoluteString, t2.url.absoluteString)
        
        let parent = try! t2.parentTask()!.get()!
        XCTAssertEqual(parent.url.absoluteString, t1.url.absoluteString)
    }
    
}
