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
import DJISDK

protocol VideoPreviewerWrapper {
    func start() -> Bool
    
    func setView(view : UIView) -> Bool
    
    func unSetView()
    
    func setDecoderWithProduct(product: DJIBaseProduct, andDecoderType decoder: VideoPreviewerDecoderType) -> Bool
    
    func push(videoData: UnsafeMutablePointer<UInt8>, length len: Int32)
}


class VideoPreviewerInstance : VideoPreviewerWrapper {
    func start() -> Bool {
        return VideoPreviewer.instance().start()
    }
    
    func setView(view: UIView) -> Bool {
        return VideoPreviewer.instance().setView(view)
    }
    
    func unSetView() {
        VideoPreviewer.instance().unSetView()
    }
    
    func setDecoderWithProduct(product: DJIBaseProduct, andDecoderType decoder: VideoPreviewerDecoderType) -> Bool {
        return VideoPreviewer.instance().setDecoderWithProduct(product, andDecoderType: decoder)
    }
    
    func push(videoData: UnsafeMutablePointer<UInt8>, length len: Int32) {
        VideoPreviewer.instance().push(videoData, length: len)
    }
}