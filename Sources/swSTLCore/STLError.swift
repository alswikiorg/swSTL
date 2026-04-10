//
//  STLError.swift
//  swSTL
//
//  Created by Craig Reyenga on 2026-04-11.
//

public struct STLError: Error, CustomStringConvertible {
    let details: String

    init(_ details: String) {
        self.details = details
    }

    public var description: String {
        details
    }
}
