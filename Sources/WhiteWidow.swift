import Foundation
import Kanna

public final class WhiteWidow {
    
    var tasks = [Task]()
    
    public func crawl(root path:String,
                      every frequency: TimeInterval) -> Task {
        let task = Task(path: path, frequency: frequency)
        tasks += [task]
        return task
    }
    
    public func run(){
        
        // 0. Add tasks root into database,
        
        // 1. Select expired links. 
        // If all are actual - schedule when the latest
        // If all once - exit
        // 2. Make a queue
        // 3. run crawlers
        
        // 4. When queue is empty go to 1.
        
    }
    
}
