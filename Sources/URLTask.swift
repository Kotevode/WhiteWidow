//
//  URLTask.swift
//  WhiteWidow
//
//  Created by ПК-1 on 03.02.17.
//
//

import Foundation
import Fluent

internal final class URLTask: Entity {
    
    static var entity = "url_tasks"
    
    var id: Node?
    var foundIn: Node?
    var url: URL
    var updateInterval: TimeInterval// 0 means fetch once
    var lastUpdate: Date?
    
    init(url: URL,
         updateInterval: TimeInterval = 0.0) {
        self.url = url
        self.updateInterval = updateInterval
    }
    
    init(node: Node, in context: Context) throws {
        self.id = try node.extract("id")
        self.url = try node.extract("url") { URL(string: $0)! }
        self.updateInterval = try node.extract("update_interval")
        if let timestamp = node["last_update"]?.double {
            self.lastUpdate = Date(timeIntervalSince1970: timestamp)
        }
        self.foundIn = node["owner_id"]
    }
    
    public func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "urltask_id": foundIn,
            "url": url.absoluteString,
            "update_interval": updateInterval,
            "last_update": lastUpdate?.timeIntervalSince1970
        ])
    }
    
    static func expired() throws -> [URLTask] {
        return try URLTask.query()
            .filter("update_interval", Filter.Comparison.notEquals, 0.0)
            .filter("last_update + update_interval", Filter.Comparison.lessThan, Date().timeIntervalSince1970)
            .all()
    }
    
}

extension URLTask: Preparation {
    
    static func prepare(_ database: Database) throws {
        try database.create("url_tasks") { (creator) in
            creator.id()
            creator.parent(URLTask.self, optional: true, unique: false, default: nil)
            creator.string("url", optional: false, unique: true)
            creator.double("update_interval")
            creator.double("last_update", optional: true, unique: false, default: nil)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("url_tasks")
    }
    
}
