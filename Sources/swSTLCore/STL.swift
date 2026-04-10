//
//  STL.swift
//  swSTL
//
//  Created by Craig Reyenga on 2026-04-10.
//

import Foundation

public struct STL {
    public let header: STLHeader
    public let facets: [Facet]

    public init(header: STLHeader, facets: [Facet]) {
        self.header = header
        self.facets = facets
    }

    public func scaled(by factor: Float32) throws -> STL {
        STL(header: header,
            facets: try facets.map { try $0.scaled(by: factor) } )
    }
}

extension STL {
    public struct Facet {
        static let expectedVerticesCount = 3

        public let normal: Vertex
        public let vertices: [Vertex]
        public let attr: UInt16?

        init(normal: Vertex, vertices: [Vertex], attr: UInt16? = nil) throws {
            guard vertices.count == STL.Facet.expectedVerticesCount else {
                throw STLError(
                    "facet: invalid number of vertices: got \(vertices.count), expected \(Self.expectedVerticesCount)"
                )
            }
            self.normal = normal
            self.vertices = vertices
            self.attr = attr
        }

        func scaled(by factor: Float32) throws -> Facet {
            try Facet(normal: normal.scaled(by: factor),
                      vertices: vertices.map { $0.scaled(by: factor) },
                      attr: attr)
        }
    }
}

extension STL {
    public struct Vertex {
        public let x: Float32
        public let y: Float32
        public let z: Float32

        init(x: Float32, y: Float32, z: Float32) {
            self.x = x
            self.y = y
            self.z = z
        }

        init(_ x: Float32, _ y: Float32, _ z: Float32) {
            self.x = x
            self.y = y
            self.z = z
        }

        var tuple: (Float32, Float32, Float32) {
            (x, y, z)
        }

        func scaled(by factor: Float32) -> Vertex {
            Vertex(x: x * factor,
                   y: y * factor,
                   z: z * factor)
        }
    }
}
