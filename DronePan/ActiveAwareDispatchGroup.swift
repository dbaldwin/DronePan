import Foundation
import CocoaLumberjackSwift

class ActiveAwareDispatchGroup {
    let group = dispatch_group_create()
    
    let name : String
    
    var active : Bool = false
    
    init(name: String) {
        self.name = name
    }
    
    func enter() {
        DDLogDebug("Entering dispatch group \(name)")
        active = true
        dispatch_group_enter(group)
    }
    
    func leave() {
        DDLogDebug("Leaving dispatch group \(name)")
        
        if !active {
            DDLogError("Warning - leaving dispatch group \(name) while not active")
        }
        
        active = false
        dispatch_group_leave(group)
    }
    
    func leaveIfActive() {
        DDLogDebug("Leaving dispatch group if active: \(active) - \(name)")
        if !active {
            self.leave()
        }
    }
    
    func wait() {
        DDLogDebug("Waiting for dispatch group \(name)")
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        DDLogDebug("Waiting complete for dispatch group \(name)")
    }
}