//
//  CrawlerTests.swift
//  WhiteWidow
//
//  Created by Mark on 05.02.17.
//
//

import XCTest
import CleanroomLogger
@testable import WhiteWidow

class CrawlerTests: XCTestCase {

    func testCanDownloadPage() {
        
        Log.enable(configuration: XcodeLogConfiguration(minimumSeverity: .verbose))
        
        let crawler = Crawler(dispatcher: nil, number: 0)
        let page = crawler.downloadPage(from: URL(string: "http://eda.ru/")!)
        
        XCTAssertNotNil(page)
        
    }

}
