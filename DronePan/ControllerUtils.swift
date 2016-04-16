import Foundation

class ControllerUtils {
    class func delay(delay: Double, queue: dispatch_queue_t, closure: () -> ()) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))),
                queue,
                closure)
    }
}