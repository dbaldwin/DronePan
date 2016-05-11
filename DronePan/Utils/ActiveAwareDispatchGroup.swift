import Foundation
import CocoaLumberjackSwift

class ActiveAwareDispatchGroup {
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

        var result = true

        if !active {
            DDLogError("Warning - leaving dispatch group \(name) while not active")

            result = false
        }

        active = false
        dispatch_group_leave(group)

        return result
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