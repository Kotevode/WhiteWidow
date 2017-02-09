import Foundation
import Kanna
import Fluent
import CleanroomLogger

/// Class for scheduling and dispatching crawling tasks
public final class WhiteWidow: Dispatcher {
    
    public var database: Database
    
    
    /// Initialization
    ///
    /// - Parameter database:database instance that should be used for storing link hierarchy
    public init(database: Database) {
        self.database = database
    }
    
    var tasks = [CrawlingTask]()
    var taskQueue = [URLTask]()
    var dispatcherQueue = DispatchQueue(label: "load_task_queue")
    var crawlers = [Crawler]()
    var running = false
    var finished = 0
    
    /// Schedule crawling
    ///
    /// - Parameters:
    ///   - path: url where crawling will start
    ///   - frequency: update frequency of path in seconds
    /// - Returns: scheduled crawling task
    public func crawl(root path:String,
                      every frequency: TimeInterval) -> CrawlingTask {
        let task = CrawlingTask(path: path, frequency: frequency)
        tasks += [task]
        return task
    }
    
    /// Start crawling
    ///
    /// - Parameters:
    ///   - crawlers: number of crawling units
    ///   - fromScratch: if true link hierarchy will be recreated
    /// - Throws: any database error
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
            Log.info?.message("Crawling done. Bye.")
        } catch let error {
            Log.error?.message(error.localizedDescription)
            Log.error?.trace()
        }
    }
    
    // TODO: Handle system signals
    func registerSignalHandlers() {
        
    }
    
    func createCrawlers(count: Int) {
        Log.verbose?.message("Creating crawlers...")
        crawlers = [Crawler]()
        for i in 0..<count {
            let c = Crawler(dispatcher: self,
                            number: i)
            crawlers += [c]
            Log.info?.message("Crawler \(i) created")
        }
        Log.verbose?.message("Done.")
    }
    
    func startCrawlers() {
        Log.verbose?.message("Starting crawlers...")
        finished = 0
        crawlers.forEach { $0.startCrawling() }
        Log.verbose?.message("Done.")
    }
    
    func prepareDatabase(fromScratch: Bool = false) throws {
        Log.verbose?.message("Preparing database \(fromScratch ? "from scratch" : "")...")
        if fromScratch {
            try? URLTask.revert(database)
            try? database.delete("fluent")
        }
        try? URLTask.prepare(database)
        Log.info?.message("Database prepared")
        Log.verbose?.message("Done.")
    }
    
    func addRootURLTasks() throws {
        Log.verbose?.message("Adding root tasks...")
        for t in tasks {
            if var alreadyScheduled = try URLTask.query()
                .filter("url", t.url.absoluteString)
                .first() {
                alreadyScheduled.lastUpdate = nil
                alreadyScheduled.updateInterval = t.frequency
                try alreadyScheduled.save()
                Log.info?.message(alreadyScheduled.description)
                return
            }
            var urlTask = URLTask(url: t.url, updateInterval: t.frequency)
            try urlTask.save()
            Log.info?.message(urlTask.description)
        }
        Log.verbose?.message("Done.")
    }
    
    func didFinishWork(_ crawler: Crawler) {
        Log.verbose?.message("Crawler \(crawler.number) did finish all work.")
        dispatcherQueue.async {
            self.finished += 1
            if self.finished == self.crawlers.count {
                Log.verbose?.message("All crawlers did finish")
                if self.loadTasks() {
                    self.startCrawlers()
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
    
    func loadTasks() -> Bool {
        Log.verbose?.message("Loading new tasks...")
        do {
            let shouldBeUpdated = try URLTask.shouldBeUpdated()
            guard shouldBeUpdated.count > 0 else {
                Log.verbose?.message("All links are fresh.")
                guard
                    let nearest = try URLTask.nearest(),
                    let nextUpdate = nearest.nextUpdate
                    else {
                        Log.info?.message("Crawling done.")
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
                Log.info?.message("Next crawling session scheduled at \(nextUpdate).")
                return false
            }
            taskQueue = shouldBeUpdated
            Log.info?.message("New tasks loaded.")
            Log.verbose?.message("Done.")
            return true
        } catch let error {
            Log.error?.message(error.localizedDescription)
            Log.error?.trace()
            return false
        }
    }
    
    func shutdown() {
        Log.verbose?.message("Shutting down...")
        self.running = false
    }
    
}
