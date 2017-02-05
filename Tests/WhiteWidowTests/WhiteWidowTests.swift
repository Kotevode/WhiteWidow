import XCTest
import Fluent
import FluentPostgreSQL
import CleanroomLogger
@testable import WhiteWidow

class WhiteWidowTests: XCTestCase {
    
    var database: Fluent.Database!
    
    override func setUp() {
        super.setUp()
        let driver = FluentPostgreSQL.PostgreSQLDriver(host: "localhost",
                                                       port: 5432,
                                                       dbname: "ww_test",
                                                       user: "ww_test",
                                                       password: "qwerty")
        database = Fluent.Database(driver)
    }
    
    func testCanCrawl(){
        
        Log.enable(configuration: XcodeLogConfiguration(minimumSeverity: .verbose))
        
        let ww = WhiteWidow(database: database)
        ww.crawl(root: "http://eda.ru/", every: 3*60)
            .add(matches: "recepty/*", expires: 120*60) { (page) in
                print("Page crawled)")
        }
        
        try! ww.run(crawlers: 4, fromScratch: true)
        
    }
    
    static var allTests : [(String, (WhiteWidowTests) -> () throws -> Void)] {
        return []
    }
}
