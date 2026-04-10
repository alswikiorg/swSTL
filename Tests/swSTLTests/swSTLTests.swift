//
//  swSTLTests.swift
//  swSTL
//
//  Created by Craig Reyenga on 2026-04-10.
//

@testable import swSTLCore
import XCTest
import Foundation

final class swSTLTests: XCTestCase {
    func testEncodeBoxAscii() throws {
        let box = STL.Fixtures.box
        let enc = try STLCoder.encode(box, outputFormat: .ascii, overrideName: nil)

        let str = String(data: enc, encoding: .ascii)
        XCTAssertNotNil(str)
    }
}
