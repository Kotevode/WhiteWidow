//
//  CrawlingTask.swift
//  WhiteWidow
//
//  Created by Mark on 02.02.17.
//
//

import Foundation
import Kanna

public class CrawlingTask {
    
    typealias PageHandler = (HTMLDocument) -> ()

    var frequency: TimeInterval
    var url: URL
    var handlers = [URLWildcard : (handler: PageHandler,
                                   frequency: TimeInterval)]()
    
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
    
}
