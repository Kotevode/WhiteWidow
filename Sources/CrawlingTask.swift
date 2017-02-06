//
//  CrawlingTask.swift
//  WhiteWidow
//
//  Created by Mark on 02.02.17.
//
//

import Foundation
import Kanna

typealias PageHandler = (String, URL) -> ()
typealias PageInfo = (handler: PageHandler, frequency: TimeInterval)

public class CrawlingTask {

    var frequency: TimeInterval
    var url: URL
    var handlers = [URLWildcard : PageInfo]()

    init(path: String, frequency: TimeInterval = 0) {
        self.url = URL(string: path)!
        self.frequency = frequency
    }

    func add(matches url: String,
             expires: TimeInterval,
             handler: @escaping PageHandler) -> Self {
        let matchingURL = URL(string: url, relativeTo: self.url)!
        let wildcard = URLWildcard(url: matchingURL)
        let wildcardOptions = (handler: handler, frequency: expires)
        handlers[wildcard] = wildcardOptions
        return self
    }

    func matches(url: URL) -> [PageInfo] {
        return handlers
            .filter { url ~= $0.key }
            .map { $0.value }
    }

}
