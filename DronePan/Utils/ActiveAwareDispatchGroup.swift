import Foundation
import CocoaLumberjackSwift

class ActiveAwareDispatchGroup : Analytics {
    let group = dispatch_group_create()

    let name: String

    var active: Bool = false

    init(name: String) {
        self.name = name
    }

    func enter() {
        DDLogDebug("Entering dispatch group \(name)")
        active = true
        dispatch_group_enter(group)
    }

    func leave() -> Bool {
        DDLogDebug("Leaving dispatch group \(name)")

        if !active {
            DDLogError("Warning - leaving dispatch group \(name) while not active")

            trackEvent(category: "System", action: "Dispatch - leave when not active", label: name)
            
            return false
        }

        active = false
        
        dispatch_group_leave(group)

        return true
    }

    func leaveIfActive() -> Bool {
        DDLogDebug("Leaving dispatch group if active: \(active) - \(name)")

        var result = false

        if active {
            self.leave()

            result = true
        }

        return result
    }

    func wait() {
        DDLogDebug("Waiting for dispatch group \(name)")
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        DDLogDebug("Waiting complete for dispatch group \(name)")
    }
}