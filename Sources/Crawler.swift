//
//  Crawler.swift
//  WhiteWidow
//
//  Created by Mark on 03.02.17.
//
//

import Foundation
import Kanna
import Alamofire

protocol Dispatcher {
    
    func getNewTask(for crawler: Crawler) -> URLTask?
    func didFinishWork(_ crawler: Crawler)
    var tasks: [CrawlingTask] { get }
    
}

final class Crawler {
    
    var dispatcher: Dispatcher?
    var crawlingQueue: DispatchQueue
    var number: Int
    
    init(dispatcher: Dispatcher, number: Int) {
        self.dispatcher = dispatcher
        self.number = number
        crawlingQueue = DispatchQueue(label: "crawling_queue_\(number)")
    }
    
    func startCrawling(){
        crawlingQueue.async {
            do {
                while let urlTask = self.dispatcher?.getNewTask(for: self) {
                    try self.process(task: urlTask)
                }
                self.dispatcher?.didFinishWork(self)
            } catch let e {
                //This will be logged
            }
        }
    }
    
    func process(task: URLTask) throws {
        guard let page = downloadPage(from: task.url) else {
            try update(task: task, withStatus: .failed)
            return
        }
        handle(url: task.url, page: page)
        try update(task: task,
                   withStatus: task.updateInterval == 0.0 ? .done : .updated)
        let extracted = extractLinks(from: page, at: task.url)
        try extracted.forEach { try update(task: $0, withStatus: .new) }
    }
    
    func extractLinks(from page: HTMLDocument, at url: URL) -> [URLTask] {
        var result = [URLTask]()
        for link in page.xpath(".//a") {
            guard
                let link = link["href"]?.string,
                let url = URL(string: link, relativeTo: url),
                let tasks = self.dispatcher?.tasks else {
                continue
            }
            let matches = tasks.reduce([PageInfo]()) {
                $0 + $1.matches(url: url)
            }
            let minUpdateInterval = matches.map { $0.frequency }
                .min()
            guard let updateInterval = minUpdateInterval else {
                continue
            }
            result += [URLTask(url: url,
                               updateInterval: updateInterval)]
        }
        return result
    }
    
    func handle(url: URL, page: HTMLDocument) {
        guard let tasks = self.dispatcher?.tasks else {
            return
        }
        for task in tasks {
            let matches = task.matches(url: url)
            for match in matches {
                match.handler(page)
            }
        }
    }
    
    func update(task: URLTask, withStatus status: URLTask.Status) throws {
        task.lastUpdate = Date()
        task.lastStatus = status
        var t = task
        try t.save()
    }
    
    func add(task: URLTask) throws {
        let alreadyAdded = try URLTask.query()
            .filter("url",
                    .equals,
                    task.url.absoluteString)
        guard try alreadyAdded.count() == 0 else {
            return
        }
        var t = task
        try t.save()
    }
    
    func downloadPage(from url: URL) -> HTMLDocument? {
        let semaphore = DispatchSemaphore(value: number)
        var result: HTMLDocument?
        Alamofire.request(url)
        .validate(contentType: ["text/html"])
        .validate(statusCode: 200..<300)
        .responseString(queue: self.crawlingQueue, encoding: .utf8) { (response) in
            switch response.result{
            case .success(let page):
                result = HTML(html: page, encoding: .utf8)
            case .failure(let error):
                //log error
            }
        }
        return result
    }
    
}
