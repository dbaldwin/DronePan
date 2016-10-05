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

class Panorama {
    var startTime : NSDate?
    var endTime : NSDate?
    
    var imageList : [String] = []
    
    var logger : PanoramaLogger?
    
    var logs = ""
    
    init() {
        logger = PanoramaLogger(panorama: self)
        
        DDLog.addLogger(logger!, withLevel: .Debug)
    }
    
    deinit {
        if let logger = self.logger {
            DDLog.removeLogger(logger)
        }
    }
    
    func log(log: String) {
        logs = logs + log
    }
}

class PanoramaLogger : DDAbstractLogger {
    var owningPanorama : Panorama!
    
    init(panorama: Panorama) {
        super.init()
        
        owningPanorama = panorama
        
        self.logFormatter = LogFormatter()
    }
    
    override func logMessage(logMessage: DDLogMessage!) {
        owningPanorama.log(logFormatter.formatLogMessage(logMessage))
    }
}

