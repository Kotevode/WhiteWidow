import Foundation
import Kanna

typealias PageHandler = (HTMLDocument) -> Void

public final class WhiteWidow {
    
    var tasks = [Task]()
    
    public func crawl(root path:String,
                      every frequency: TimeInterval) -> Task {
        let task = Task(path: path, frequency: frequency)
        tasks += [task]
        return task
    }
    
    public func run(){
        
    }
    
}
