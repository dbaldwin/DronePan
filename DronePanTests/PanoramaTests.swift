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

import XCTest

@testable import DronePan

class PanoramaTests: XCTestCase {
    func testStartAndFinish() {
        let panorama = Panorama()
        
        XCTAssertNotNil(panorama.startTime)
        XCTAssertNil(panorama.endTime)
        
        panorama.finish()
        
        XCTAssertNotNil(panorama.startTime)
        XCTAssertNotNil(panorama.endTime)
        
        XCTAssertTrue(panorama.endTime!.timeIntervalSinceDate(panorama.startTime!) > 0)
    }
    
    func testFilenames() {
        let panorama = Panorama()
        
        XCTAssertEqual(panorama.imageList.count, 0)
        
        panorama.addFilename("File1");
        panorama.addFilename("File2");
        panorama.addFilename("File3");

        XCTAssertEqual(panorama.imageList.count, 3)
        
        for i in 0..<3 {
            XCTAssertEqual(panorama.imageList[i], "File\(i + 1)")
        }
    }
}
