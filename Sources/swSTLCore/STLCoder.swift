//
//  STLCoder.swift
//  swSTL
//
//  Created by Craig Reyenga on 2026-04-10.
//

import Foundation

public enum STLCoder {
    public static func encode(_ src: STL, outputFormat: STLFormat, overrideName: String?) throws -> Data {
        switch outputFormat {
        case .ascii:
            return try encodeAscii(src, overrideName: overrideName)
        case .binary:
            return try encodeBinary(src, name: overrideName)
        }
    }

    public static func decode(_ src: Data) throws -> STL {
        guard src.count >= binHeaderSize else {
            return try decodeAscii(src)
        }

        do {
            return try decodeAscii(src)
        } catch {
            return try decodeBinary(src)
        }
    }

    static func decodeAscii(_ src: Data) throws -> STL {
        guard let src = String(data: src, encoding: .ascii) else {
            throw STLError("invalid STL: could not decode as ASCII")
        }

        let lines = src
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        guard lines.count >= 9 else { // 9 = 3x3 = one facet
            throw STLError("invalid STL: invalid ASCII format: fewer lines than expected")
        }

        let header = lines[0].trimmingCharacters(in: .whitespaces)
        let headerSplit = header.split(separator: " ")

        guard headerSplit.count >= 2, headerSplit[0].hasPrefix("solid") else {
            throw STLError("invalid STL: invalid ASCII format: invalid header")
        }

        let name = headerSplit[1...].joined(separator: " ")

        struct PartialFacet {
            var normal: STL.Vertex? = nil
            var didSeeLoopStart: Bool = false
            var didSeeLoopEnd: Bool = false
            var vertices: [STL.Vertex] = []

            func facet() -> STL.Facet? {
                guard
                    let normal,
                    vertices.count == STL.Facet.expectedVerticesCount,
                    didSeeLoopStart,
                    didSeeLoopEnd
                else {
                    return nil
                }

                return try? STL.Facet(normal: normal, vertices: vertices)
            }
        }

        var facets: [STL.Facet] = []
        var partialFacet: PartialFacet? = nil
        var didSeeEndSolid: Bool = false

        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            if line.isEmpty {
                continue
            }

            if line.hasPrefix("facet normal") {
                guard partialFacet == nil else {
                    throw STLError("invalid STL: invalid ASCII format: previous facet not closed; line \(i)")
                }

                partialFacet = .init()

                guard let vertex = ascii2vertex(String(line.dropFirst("facet normal".count))) else {
                    throw STLError("invalid STL: invalid ASCII format: normal could not be read; line \(i)")
                }

                partialFacet!.normal = .init(vertex.0, vertex.1, vertex.2)

            } else if line.hasPrefix("outer loop") {
                guard partialFacet != nil else {
                    throw STLError("invalid STL: invalid ASCII format: starting a facet vertex loop while not in a facet; line \(i)")
                }

                partialFacet!.didSeeLoopStart = true

            } else if line.hasPrefix("vertex") {
                guard partialFacet != nil else {
                    throw STLError("invalid STL: invalid ASCII format: vertex defined with no associated facet; line \(i)")
                }

                guard partialFacet!.didSeeLoopStart else {
                    throw STLError("invalid STL: invalid ASCII format: vertex defined with no facet loop start; line \(i)")
                }

                guard partialFacet!.vertices.count < STL.Facet.expectedVerticesCount else {
                    throw STLError("invalid STL: invalid ASCII format: vertex defined but we have already found \(STL.Facet.expectedVerticesCount); line \(i)")
                }

                guard !partialFacet!.didSeeLoopEnd else {
                    throw STLError("invalid STL: invalid ASCII format: vertex defined after facet loop ended; line \(i)")
                }

                guard let vertex = ascii2vertex(String(line.dropFirst("vertex".count))) else {
                    throw STLError("invalid STL: invalid ASCII format: vertex could not be read; line \(i)")
                }

                partialFacet!.vertices.append(.init(vertex.0, vertex.1, vertex.2))

            } else if line.hasPrefix("endloop") {
                guard partialFacet != nil else {
                    throw STLError("invalid STL: invalid ASCII format: previous facet not closed; line \(i)")
                }

                guard partialFacet!.didSeeLoopStart else {
                    throw STLError("invalid STL: invalid ASCII format: facet loop ended ahead of facet loop start; line \(i)")
                }

                guard partialFacet!.vertices.count == STL.Facet.expectedVerticesCount else {
                    throw STLError("invalid STL: invalid ASCII format: facet loop ended with unexpected number of vertices: got \(partialFacet!.vertices.count), need \(STL.Facet.expectedVerticesCount); line \(i)")
                }

                partialFacet!.didSeeLoopEnd = true

            } else if line.hasPrefix("endfacet") {
                guard let facet = partialFacet?.facet() else {
                    throw STLError("invalid STL: invalid ASCII format: facet is closed but invalid; line \(i)")
                }

                facets.append(facet)

                partialFacet = nil

            } else if line.hasPrefix("endsolid") {
                guard partialFacet == nil else {
                    throw STLError("invalid STL: invalid ASCII format: last facet not closed; line \(i)")
                }

                didSeeEndSolid = true

            }

        }

        guard didSeeEndSolid else {
            throw STLError("invalid STL: invalid ASCII format: no `endsolid` found")
        }

        return STL(header: .ascii(.init(name: name)), facets: facets)
    }

    static func decodeBinary(_ src: Data) throws -> STL {
        let headerData = Data(src.prefix(binHeaderSize))

        let src = src.dropFirst(binHeaderSize)

        let facetCountValueSize: Int = MemoryLayout<UInt32>.size

        guard (src.count - facetCountValueSize) % binFacetSize == 0 else {
            throw STLError("invalid STL: invalid binary format: unexpected size")
        }

        let facetCount = src.prefix(facetCountValueSize).withUnsafeBytes {
            $0.load(as: UInt32.self)
        }.littleEndian

        let facetsDataSize = Int(facetCount) * binFacetSize

        guard (src.count - facetCountValueSize) == facetsDataSize else {
            throw STLError("invalid STL: invalid binary format: unexpected size for facets, count: \(facetCount), expected size: \(facetsDataSize), actual size: \(src.count - facetCountValueSize)")
        }

        var facets: [STL.Facet] = []
        facets.reserveCapacity(Int(facetCount))

        for offset in stride(from: facetCountValueSize, to: src.count, by: binFacetSize) {
            let o = MemoryLayout<Float32>.size

            let nx: Float32 = try data2real32(src, offset: offset)
            let ny: Float32 = try data2real32(src, offset: offset + o)
            let nz: Float32 = try data2real32(src, offset: offset + o * 2)

            let v1x: Float32 = try data2real32(src, offset: offset + o * 3)
            let v1y: Float32 = try data2real32(src, offset: offset + o * 4)
            let v1z: Float32 = try data2real32(src, offset: offset + o * 5)

            let v2x: Float32 = try data2real32(src, offset: offset + o * 6)
            let v2y: Float32 = try data2real32(src, offset: offset + o * 7)
            let v2z: Float32 = try data2real32(src, offset: offset + o * 8)

            let v3x: Float32 = try data2real32(src, offset: offset + o * 9)
            let v3y: Float32 = try data2real32(src, offset: offset + o * 10)
            let v3z: Float32 = try data2real32(src, offset: offset + o * 11)

            let attr: UInt16 = try data2uint16(src, offset: offset + o * 12)

            let facet = try STL.Facet(
                normal: .init(x: nx, y: ny, z: nz),
                vertices: [
                    .init(x: v1x, y: v1y, z: v1z),
                    .init(x: v2x, y: v2y, z: v2z),
                    .init(x: v3x, y: v3y, z: v3z)
                ],
                attr: attr
            )

            facets.append(facet)
        }

        return STL(header: try .init(binaryData: headerData), facets: facets)
    }
}

// MARK: - Encode ASCII

fileprivate extension STLCoder {
    static func encodeAscii(_ src: STL, overrideName: String?) throws -> Data {
        let n = [
            overrideName,
            src.header.ascii?.name,
            ""
        ].compactMap { $0 }.first!

        let start = "solid \(n)\(newline)"
        let facets = try src.facets
            .map { try encodeFacetAscii($0) }
        let end = "endsolid \(n)\(newline)"

        var d = Data()
        d += try ascii2data(start)
        facets.forEach { d += $0 }
        d += try ascii2data(end)

        return d
    }

    static func encodeFacetAscii(_ src: STL.Facet) throws -> Data {
        let start = try encodeVertexAscii(src.normal,
                                          indentLevel: 1,
                                          prefix: "facet normal ",
                                          newline: newline)
        let start2 = indent(src: "outer loop\(newline)", 2)

        let vertices = try src.vertices
            .map { try encodeVertexAscii($0, indentLevel: 3, prefix: "vertex ", newline: newline) }

        let end = indent(src: "endloop\(newline)", 2)
        let end2 = indent(src: "endfacet\(newline)", 1)

        var d = Data()
        d += start
        d += try ascii2data(start2)
        vertices.forEach { d += $0 }
        d += try ascii2data(end)
        d += try ascii2data(end2)

        return d
    }

    static func encodeVertexAscii(_ src: STL.Vertex,
                                  indentLevel: Int,
                                  prefix: String = "",
                                  newline: String) throws -> Data {
        let s = indent(src: "\(prefix)\(src.x) \(src.y) \(src.z)\(newline)", indentLevel)
        return try ascii2data(s)
    }
}

// MARK: - Encode Binary

fileprivate extension STLCoder {
    static func encodeBinary(_ src: STL, name: String?) throws -> Data {
        var header = Data(repeating: 0, count: binHeaderSize)

        if let name = name {
            let nameData = try ascii2data(name)
            header.replaceSubrange(0..<nameData.count, with: nameData)
        } else {
            let nameData = try ascii2data("\(APP_NAME)_\(APP_VERSION)")
            header.replaceSubrange(0..<nameData.count, with: nameData)
        }

        var fc = UInt32(src.facets.count).littleEndian
        let facetsCount = withUnsafeBytes(of: &fc) { Data($0) }

        let facets = try src.facets
            .map { try encodeFacetBinary($0) }

        var out = Data()

        out.append(header)
        out.append(facetsCount)
        facets.forEach { out.append($0) }

        return out
    }

    static func encodeFacetBinary(_ src: STL.Facet) throws -> Data {
        var out = Data()

        out += vertex2binary(src.normal.tuple)

        src.vertices.forEach {
            out += vertex2binary($0.tuple)
        }

        out += uint16toBinary(src.attr ?? 0)

        return out
    }
}

// MARK: - Utilities

fileprivate extension STLCoder {
    static let newline: String = "\n"
    static let indentStr: String = " "
    static let binHeaderSize: Int = 80
    static let binFacetSize: Int = 50

    static func indent(src: String, _ level: Int) -> String {
        guard level > 0 else { return src }
        let indent = String(repeating: indentStr, count: level)
        return indent + src
    }

    static func ascii2data(_ src: String) throws -> Data {
        guard let out = src.data(using: .ascii) else {
            throw STLError("unable to convert string to data")
        }
        return out
    }

    static func ascii2vertex(_ src: String) -> (Float32, Float32, Float32)? {
        let scanner = Scanner(string: src)
        scanner.charactersToBeSkipped = .whitespacesAndNewlines

        var x: Float32 = 0
        var y: Float32 = 0
        var z: Float32 = 0

        guard scanner.scanFloat(&x),
              scanner.scanFloat(&y),
              scanner.scanFloat(&z) else {
            return nil
        }

        return (x, y, z)
    }

    static func data2real32(_ src: Data, offset: Int) throws -> Float32 {
        let value = src.withUnsafeBytes {
            $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self)
        }

        return Float32(bitPattern: UInt32(littleEndian: value))
    }

    static func data2uint16(_ src: Data, offset: Int) throws -> UInt16 {
        let value = src.withUnsafeBytes {
            $0.loadUnaligned(fromByteOffset: offset, as: UInt16.self)
        }

        return UInt16(littleEndian: value)
    }

    static func vertex2binary(_ src: (Float32, Float32, Float32)) -> Data {
        var out = Data()

        out += real32toBinary(src.0)
        out += real32toBinary(src.1)
        out += real32toBinary(src.2)

        return out
    }

    static func real32toBinary(_ src: Float32) -> Data {
        var out = Data()

        var value = src.bitPattern.littleEndian
        withUnsafeBytes(of: &value) {
            out.append($0.bindMemory(to: UInt8.self))
        }

        return out
    }

    static func uint16toBinary(_ src: UInt16) -> Data {
        var out = Data()

        var value = src.littleEndian
        withUnsafeBytes(of: &value) {
            out.append($0.bindMemory(to: UInt8.self))
        }

        return out
    }
}
