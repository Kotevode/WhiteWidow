import Foundation
import Kanna
import Fluent

public final class WhiteWidow {
    
    var database: Database
    
    init(database: Database) {
        self.database = database
    }
    
    var tasks = [CrawlingTask]()
    var taskQueue = [URLTask]()
    var loadTaskQueue = DispatchQueue(label: "load_task_queue")
    var crawlers = [Crawler]()
    
    public func crawl(root path:String,
                      every frequency: TimeInterval) -> CrawlingTask {
        let task = CrawlingTask(path: path, frequency: frequency)
        tasks += [task]
        return task
    }
    
    public func run(crawlers: Int,
                    fromScratch: Bool = false) throws {
        try prepareDatabase()
        try addRootURLTasks()
        createCrawlers(count: crawlers)
        while true {}
    }
    
    func createCrawlers(count: Int){
        crawlers = [Crawler]()
        for _ in 0..<count {
            let c = Crawler(dispatcher: self)
            c.startCrawling()
            crawlers += [c]
        }
    }
    
    private func prepareDatabase(fromScratch: Bool = false) throws {
        if fromScratch {
            try URLTask.revert(database)
        }
        try URLTask.prepare(database)
    }
    
    private func addRootURLTasks() throws {
        for t in tasks {
            if var alreadyScheduled = try URLTask.query()
                .filter("url", t.url.absoluteString)
                .first() {
                alreadyScheduled.lastUpdate = nil
                alreadyScheduled.updateInterval = t.frequency
                try alreadyScheduled.save()
                return
            }
            var urlTask = URLTask(url: t.url, updateInterval: t.frequency)
            try urlTask.save()
        }
    }
    
    func popURLTask() throws -> URLTask? {
        var result: URLTask?
        try loadTaskQueue.sync {
            result = taskQueue.popLast()
            guard result != nil else {
                if try loadTasks() {
                    result = try popURLTask()
                }
                return
            }
        }
        return result
    }
    
    private func loadTasks() throws -> Bool {
        let expired = try URLTask.expired()
        guard expired.count > 0 else {
            return false
        }
        taskQueue = expired
        return true
    }
    
}
