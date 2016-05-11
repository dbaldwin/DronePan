//
//  PreviewControllerTests.swift
//  DronePan
//
//  Created by Chris Searle on 11/05/16.
//  Copyright © 2016 Unmanned Airlines, LLC. All rights reserved.
//

import XCTest
import DJISDK

@testable import DronePan

class TestablePreviewController: PreviewController {
    var internalPreviewer: VideoPreviewer

    init(previewer: VideoPreviewer) {
        self.internalPreviewer = previewer
    }

    override var previewer: VideoPreviewer {
        return internalPreviewer
    }
}

class PreviewControllerTests: XCTestCase {
    func testStart() {

        class VideoPreviewerMock: VideoPreviewer {
            var startCalled: Bool?
            var viewSeen: UIView?

            override func start() -> Bool {
                startCalled = true

                return true
            }

            override func setView(view: UIView!) -> Bool {
                viewSeen = view

                return true
            }
        }

        let previewer = VideoPreviewerMock()
        let view = UIView()

        let controller = TestablePreviewController(previewer: previewer)

        controller.startWithView(view)

        XCTAssertTrue(previewer.startCalled!, "Previewer didn't start")
        XCTAssertEqual(previewer.viewSeen!, view, "Previewer didn't see view")
    }

    func testHardwareDecoder() {

        class VideoPreviewerMock: VideoPreviewer {
            override func setDecoderWithProduct(product: DJIBaseProduct!, andDecoderType decoder: VideoPreviewerDecoderType) -> Bool {
                if decoder == .HardwareDecoder {
                    return true
                }

                return false
            }
        }

        let previewer = VideoPreviewerMock()

        let controller = TestablePreviewController(previewer: previewer)

        let type = controller.setMode(DJIBaseProduct())

        XCTAssertEqual(type, DecoderType.Hardware, "Expected hardware decoding got \(type)")
    }

    func testSoftwareDecoder() {

        class VideoPreviewerMock: VideoPreviewer {
            override func setDecoderWithProduct(product: DJIBaseProduct!, andDecoderType decoder: VideoPreviewerDecoderType) -> Bool {
                if decoder == .HardwareDecoder {
                    return false
                }

                return true
            }
        }

        let previewer = VideoPreviewerMock()

        let controller = TestablePreviewController(previewer: previewer)

        let type = controller.setMode(DJIBaseProduct())

        XCTAssertEqual(type, DecoderType.Software, "Expected software decoding got \(type)")
    }

    func testUnknownDecoder() {

        class VideoPreviewerMock: VideoPreviewer {
            override func setDecoderWithProduct(product: DJIBaseProduct!, andDecoderType decoder: VideoPreviewerDecoderType) -> Bool {
                return false
            }
        }

        let previewer = VideoPreviewerMock()

        let controller = TestablePreviewController(previewer: previewer)

        let type = controller.setMode(DJIBaseProduct())

        XCTAssertEqual(type, DecoderType.Unknown, "Expected unknown decoding got \(type)")
    }

    func testVideo() {

        class VideoPreviewerMock: VideoPreviewer {
            var seenData: UnsafeMutablePointer<UInt8>?
            var seenLength: Int32?

            override func push(videoData: UnsafeMutablePointer<UInt8>, length len: Int32) {
                seenData = videoData
                seenLength = len
            }
        }

        let previewer = VideoPreviewerMock()

        let controller = TestablePreviewController(previewer: previewer)

        let length = 20
        let buffer = UnsafeMutablePointer<UInt8>.alloc(length)

        for index in 0 ..< length {
            buffer[index] = UInt8(index)
        }

        controller.cameraReceivedVideo(buffer, size: length)

        XCTAssertEqual(previewer.seenLength!, Int32(length), "Previewer didn't see length")

        for index in 0 ..< length {
            let expected = UInt8(index)
            let actual = previewer.seenData![index] as UInt8

            XCTAssertEqual(actual, expected, "Previewer didn't see correct data \(expected) for index \(index) - saw \(actual)")
        }
    }
}
