//
//  URLTask.swift
//  WhiteWidow
//
//  Created by ПК-1 on 03.02.17.
//
//

import Foundation
import Fluent

internal final class URLTask: Entity, CustomStringConvertible {
    
    enum Status: String {
        case new = "new"
        case done = "done"
        case updated = "updated"
        case failed = "failed"
    }
    
    static var entity = "url_tasks"
    var exists: Bool = false
    
    var id: Node?
    var foundIn: Node?
    var url: URL
    var updateInterval: TimeInterval// 0 means fetch once
    var lastUpdate: Date?
    var lastStatus = Status.new
    var nextUpdate: Date? {
        guard lastUpdate != nil && updateInterval != 0 else {
            return nil
        }
        return lastUpdate!.addingTimeInterval(updateInterval)
    }
    
    var description: String {
        var result = ["URLTask: \(url.absoluteString)"]
        result += ["update interval: \(updateInterval)"]
        if lastUpdate != nil {
            result += ["last update: \(lastUpdate!)"]
        }
        result += ["last status: \(lastStatus.rawValue)"]
        return result.joined(separator: ", ")
    }
    
    func parentTask() throws -> Parent<URLTask>? {
        return try self.parent(foundIn)
    }
    
    func childrenTasks() -> Children<URLTask> {
        return self.children("urltask_id", URLTask.self)
    }
    
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
        self.lastStatus = Status(rawValue: try node.extract("last_status"))!
    }
    
    public func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "urltask_id": foundIn,
            "url": url.absoluteString,
            "update_interval": updateInterval,
            "last_update": lastUpdate?.timeIntervalSince1970,
            "last_status": lastStatus.rawValue
            ])
    }
    
    static func expired() throws -> [URLTask] {
        return try URLTask.query()
            .filter("last_status",
                    .notEquals,
                    Status.done.rawValue)
            .filter("last_update + update_interval",
                    .lessThan,
                    Date().timeIntervalSince1970)
            .all()
    }
    
    static func shouldBeUpdated() throws -> [URLTask] {
        return try URLTask.query()
            .or({ (query) in
                try query
                    .filter("last_status",
                            .in,
                            [ Status.new.rawValue , Status.failed.rawValue ])
                    .and({ (query) in
                        try query
                            .filter("last_update + update_interval",
                                    .lessThan,
                                    Date().timeIntervalSince1970)
                            .filter("last_status",
                                    .equals,
                                    Status.updated.rawValue)
                    })
            })
            .all()
    }
    
    static func nearest() throws -> URLTask? {
        return try URLTask.query()
            .filter("last_update + update_interval",
                    Filter.Comparison.greaterThan,
                    Date().timeIntervalSince1970)
            .sort("last_update + update_interval",
                  Sort.Direction.ascending)
            .limit(1)
            .first()
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
            creator.string("last_status")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("url_tasks")
    }
    
}
