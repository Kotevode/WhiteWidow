//
//  Task.swift
//  WhiteWidow
//
//  Created by Mark on 02.02.17.
//
//

import Foundation

public class Task {
    
    var frequency: TimeInterval
    var path: String
    
    init(path: String, frequency: TimeInterval = 0) {
        self.path = path
        self.frequency = frequency
    }
    
    func add(/*handler: PageHandler, maches: String, expires*/) -> Self {
        return self
    }
}
