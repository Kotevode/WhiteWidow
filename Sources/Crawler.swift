//
//  Crawler.swift
//  WhiteWidow
//
//  Created by Mark on 03.02.17.
//
//

import Foundation
import Kanna
import CleanroomLogger

protocol Dispatcher {
    
    func getNewTask(for crawler: Crawler) -> URLTask?
    func didFinishWork(_ crawler: Crawler)
    var tasks: [CrawlingTask] { get }
    
}

final class Crawler {
    
    var dispatcher: Dispatcher?
    var crawlingQueue: DispatchQueue
    var number: Int
    
    init(dispatcher: Dispatcher?, number: Int) {
        self.dispatcher = dispatcher
        self.number = number
        crawlingQueue = DispatchQueue(label: "crawling_queue_\(number)")
    }
    
    func startCrawling(){
        Log.info?.message("Crawler \(number): started")
        crawlingQueue.async {
            do {
                while let urlTask = self.dispatcher?.getNewTask(for: self) {
                    try self.process(task: urlTask)
                }
                self.dispatcher?.didFinishWork(self)
            } catch let error {
                Log.verbose?.message("Crawler \(self.number): \(error.localizedDescription)")
                Log.verbose?.trace()
            }
        }
    }
    
    func process(task: URLTask) throws {
        Log.verbose?.message("Crawler \(self.number): Processing task: \(task.description)")
        guard let page = downloadPage(from: task.url) else {
            Log.warning?.message("Crawler \(self.number): Cannot download page")
            try update(task: task, withStatus: .failed)
            return
        }
        handle(url: task.url, page: page)
        try update(task: task,
                   withStatus: task.updateInterval == 0.0 ? .done : .updated)
        let extracted = extractLinks(from: page, at: task.url)
        try extracted.forEach { try add(task: $0) }
        Log.verbose?.message("Crawler \(self.number): Done.")
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
        Log.verbose?.message("Crawler \(self.number): Calling page handlers...")
        for task in tasks {
            let matches = task.matches(url: url)
            for match in matches {
                match.handler(page)
            }
        }
        Log.verbose?.message("Crawler \(self.number): Done.")
    }
    
    func update(task: URLTask, withStatus status: URLTask.Status) throws {
        Log.verbose?.message("Crawler \(self.number): Updating task...")
        task.lastUpdate = Date()
        task.lastStatus = status
        var t = task
        try t.save()
        Log.info?.message("Crawler \(self.number), Task updated: \(task.description)")
        Log.verbose?.message("Done.")
    }
    
    func add(task: URLTask) throws {
        Log.verbose?.message("Crawler \(self.number): Creating task...")
        let alreadyAdded = try URLTask.query()
            .filter("url",
                    .equals,
                    task.url.absoluteString)
        guard try alreadyAdded.count() == 0 else {
            Log.verbose?.message("Crawler \(self.number): Task has already added.")
            return
        }
        var t = task
        try t.save()
        Log.info?.message("Crawler \(self.number): Task \(task.description) added")
        Log.verbose?.message("Done.")
    }
    
    func downloadPage(from url: URL) -> HTMLDocument? {
        Log.verbose?.message("Crawler \(self.number): Downloading page from \(url.absoluteString)...")
        let semaphore = DispatchSemaphore(value: 0)
        var result: HTMLDocument?
        let session = URLSession.shared
        let task = session.dataTask(with: url) { (data, resposne, error) in
            guard let data = data else {
                Log.warning?.message("Crawler \(self.number): \(error!.localizedDescription)")
                return
            }
            result = HTML(html: data, encoding: .utf8)
            semaphore.signal()
        }
        task.resume()
        semaphore.wait(timeout: .distantFuture)
        Log.verbose?.message("Crawler \(self.number): Done.")
        return result
    }
    
}
