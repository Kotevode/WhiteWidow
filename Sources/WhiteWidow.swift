import Foundation
import Kanna
import Fluent
import CleanroomLogger

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
        Log.enable()
        do {
            try prepareDatabase()
            try addRootURLTasks()
            registerSignalHandlers()
            createCrawlers(count: crawlers)
            if loadTasks() {
                startCrawlers()
                running = true
            }
            while running {}
            Log.verbose?.message("Crawling done. Bye.")
        } catch let error {
            Log.error?.message(error.localizedDescription)
            Log.error?.trace()
        }
    }
    
    func registerSignalHandlers() {
        
    }
    
    func createCrawlers(count: Int){
        Log.verbose?.message("Creating crawlers...")
        crawlers = [Crawler]()
        for i in 0..<count {
            let c = Crawler(dispatcher: self,
                            number: i)
            crawlers += [c]
            Log.verbose?.message("Crawler \(i) created")
        }
        Log.verbose?.message("Done.")
    }
    
    func startCrawlers() {
        Log.verbose?.message("Starting crawlers...")
        finished = 0
        crawlers.forEach { $0.startCrawling() }
        Log.verbose?.message("Done.")
    }
    
    private func prepareDatabase(fromScratch: Bool = false) throws {
        Log.verbose?.message("Preparing database \(fromScratch ? "from scratch" : "")...")
        if fromScratch {
            try URLTask.revert(database)
            try database.delete("fluent")
        }
        try URLTask.prepare(database)
        Log.verbose?.message("Done.")
    }
    
    private func addRootURLTasks() throws {
        Log.verbose?.message("Adding root tasks...")
        for t in tasks {
            if var alreadyScheduled = try URLTask.query()
                .filter("url", t.url.absoluteString)
                .first() {
                alreadyScheduled.lastUpdate = nil
                alreadyScheduled.updateInterval = t.frequency
                try alreadyScheduled.save()
                Log.debug?.message(alreadyScheduled.description)
                return
            }
            var urlTask = URLTask(url: t.url, updateInterval: t.frequency)
            try urlTask.save()
            Log.debug?.message(urlTask.description)
        }
        Log.verbose?.message("Done.")
    }
    
    func didFinishWork(_ crawler: Crawler) {
        Log.verbose?.message("Crawler \(crawler.number) did finish all work.")
        dispatcherQueue.sync {
            finished += 1
            if finished == crawlers.count {
                Log.verbose?.message("All crawlers did finish")
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
        Log.verbose?.message("Loading new tasks...")
        do {
            let shouldBeUpdated = try URLTask.shouldBeUpdated()
            guard shouldBeUpdated.count > 0 else {
                Log.verbose?.message("All links are fresh.")
                guard
                    let nearest = try URLTask.nearest(),
                    let nextUpdate = nearest.nextUpdate
                    else {
                        Log.verbose?.message("Crawling done.")
                        shutdown()
                        return false
                }
                Log.verbose?.message("Scheduling next crawling session.")
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
            Log.verbose?.message("Done.")
            return true
        } catch let error {
            Log.error?.message(error.localizedDescription)
            Log.error?.trace()
            return false
        }
    }
    
    private func shutdown() {
        Log.verbose?.message("Shutting down...")
        DispatchQueue.main.async {
            self.running = false
        }
    }
    
}
