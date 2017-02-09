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
        
        let whiteWidow = WhiteWidow(database: database)
        whiteWidow.crawl(root: "http://eda.ru/recepty/", every: 0)
            .add(matches: "*/lazanja-klassicheskaja-s-mjasom-31799", expires: 0) { (page, url) in
                print("Page at \(url.absoluteString) crawled")
        }
        
        try! whiteWidow.run(crawlers: 4, fromScratch: true)
    }
    
    func testCanPrepareDatabase(){
        let whiteWidow = WhiteWidow(database: database)
        try! whiteWidow.prepareDatabase(fromScratch: true)
        try! whiteWidow.prepareDatabase(fromScratch: false)
    }
    
    static var allTests : [(String, (WhiteWidowTests) -> () throws -> Void)] {
        return []
    }
}
