/*
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation

import CocoaLumberjackSwift

class LogFormatter : NSObject, DDLogFormatter {
    let dateFormatter : NSDateFormatter
    
    override init() {
        dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss:SSS"
    }
    
    @objc func formatLogMessage(logMessage: DDLogMessage!) -> String! {
        var logPrefix : String
        
        switch (logMessage.flag) {
        case DDLogFlag.Error:
            logPrefix = "E"
        case DDLogFlag.Warning:
            logPrefix = "W"
        case DDLogFlag.Info:
            logPrefix = "I"
        case DDLogFlag.Debug:
            logPrefix = "D"
        default:
            logPrefix = "V"
        }

        return "\(logPrefix): \(dateFormatter.stringFromDate(logMessage.timestamp)) [\(logMessage.queueLabel)/\(logMessage.threadID)] \(logMessage.fileName) \(logMessage.function) line: \(logMessage.line) \(logMessage.message)"
    }
}