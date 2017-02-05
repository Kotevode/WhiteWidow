import Foundation
import Kanna
import Fluent

public final class WhiteWidow: Dispatcher {
    
    var database: Database
    
    init(database: Database) {
        self.database = database
    }
    
    var tasks = [CrawlingTask]()
    var taskQueue = [URLTask]()
    var dispatcherQueue = DispatchQueue(label: "load_task_queue")
    var crawlers = [Crawler]()
    var running = false
    var finished = 0
    
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
        registerSignalHandlers()
        createCrawlers(count: crawlers)
        running = true
        while running {}
    }
    
    func registerSignalHandlers() {
        
    }
    
    func createCrawlers(count: Int){
        crawlers = [Crawler]()
        for i in 0..<count {
            let c = Crawler(dispatcher: self,
                            number: i)
            crawlers += [c]
        }
    }
    
    func startCrawlers() {
        finished = 0
        crawlers.forEach { $0.startCrawling() }
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
    
    func didFinishWork(_ crawler: Crawler) {
        dispatcherQueue.sync {
            finished += 1
            if finished == crawlers.count {
                dispatcherQueue.async {
                    if self.loadTasks() {
                        self.startCrawlers()
                    }
                }
            }
        }
    }
    
    func getNewTask(for crawler: Crawler) -> URLTask? {
        var result: URLTask?
        dispatcherQueue.sync {
            result = taskQueue.popLast()
        }
        return result
    }
    
    private func loadTasks() -> Bool {
        do {
            let shouldBeUpdated = try URLTask.shouldBeUpdated()
            guard shouldBeUpdated.count > 0 else {
                guard
                    let nearest = try URLTask.nearest(),
                    let nextUpdate = nearest.nextUpdate
                    else {
                        shutdown()
                        return false
                }
                let deadline: DispatchTime =
                    .now() + DispatchTimeInterval.seconds(Int(nextUpdate.timeIntervalSinceNow))
                dispatcherQueue.asyncAfter(deadline: deadline, execute: { 
                    if self.loadTasks() {
                        self.startCrawlers()
                    }
                })
                return false
            }
            taskQueue = shouldBeUpdated
            return true
        } catch let e {
            return false
        }
    }
    
    private func shutdown() {
        DispatchQueue.main.async {
            self.running = false
        }
    }
    
}
