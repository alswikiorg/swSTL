//
//  STLHeader.swift
//  swSTL
//
//  Created by Craig Reyenga on 2026-04-17.
//

import Foundation

public enum STLHeader: Hashable, CustomStringConvertible {
    case ascii(Ascii)
    case binary(Binary)

    public init(binaryData: Data) throws {
        self = .binary(Binary(data: binaryData))
    }

    public init(asciiName: String?) throws {
        self = .ascii(Ascii(name: asciiName))
    }

    public var ascii: Ascii? {
        guard case let .ascii(ascii) = self else { return nil }
        return ascii
    }

    public var binary: Binary? {
        guard case let .binary(binary) = self else { return nil }
        return binary
    }

    public var description: String {
        switch self {
        case .ascii(let info):
            if let name = info.name {
                return "ASCII(\"\(name)\")"
            } else {
                return "ASCII(nil)"
            }
        case .binary:
            return "BINARY"
        }
    }
}

extension STLHeader {
    public struct Ascii: Hashable {
        let name: String?
    }
}

extension STLHeader {
    public struct Binary: Hashable {
        let data: Data
    }
}
