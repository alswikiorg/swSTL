//
//  STL+Fixtures.swift
//  swSTL
//
//  Created by Craig Reyenga on 2026-04-10.
//

extension STL {
    public enum Fixtures {
        /// a 1x1x1 cube
        nonisolated(unsafe) static let box: STL = STL(
            header: .ascii(.init(name: "box")),
            facets: [
                // Bottom (z = 0)
                try! .init(
                    normal: .init(0, 0, -1),
                    vertices: [
                        .init(0, 0, 0),
                        .init(1, 1, 0),
                        .init(1, 0, 0)
                    ]
                ),
                try! .init(
                    normal: .init(0, 0, -1),
                    vertices: [
                        .init(0, 0, 0),
                        .init(0, 1, 0),
                        .init(1, 1, 0)
                    ]
                ),

                // Top (z = 1)
                try! .init(
                    normal: .init(0, 0, 1),
                    vertices: [
                        .init(0, 0, 1),
                        .init(1, 0, 1),
                        .init(1, 1, 1)
                    ]
                ),
                try! .init(
                    normal: .init(0, 0, 1),
                    vertices: [
                        .init(0, 0, 1),
                        .init(1, 1, 1),
                        .init(0, 1, 1)
                    ]
                ),

                // Front (y = 0)
                try! .init(
                    normal: .init(0, -1, 0),
                    vertices: [
                        .init(0, 0, 0),
                        .init(1, 0, 0),
                        .init(1, 0, 1)
                    ]
                ),
                try! .init(
                    normal: .init(0, -1, 0),
                    vertices: [
                        .init(0, 0, 0),
                        .init(1, 0, 1),
                        .init(0, 0, 1)
                    ]
                ),

                // Back (y = 1)
                try! .init(
                    normal: .init(0, 1, 0),
                    vertices: [
                        .init(0, 1, 0),
                        .init(1, 1, 1),
                        .init(1, 1, 0)
                    ]
                ),
                try! .init(
                    normal: .init(0, 1, 0),
                    vertices: [
                        .init(0, 1, 0),
                        .init(0, 1, 1),
                        .init(1, 1, 1)
                    ]
                ),

                // Left (x = 0)
                try! .init(
                    normal: .init(-1, 0, 0),
                    vertices: [
                        .init(0, 0, 0),
                        .init(0, 0, 1),
                        .init(0, 1, 1)
                    ]
                ),
                try! .init(
                    normal: .init(-1, 0, 0),
                    vertices: [
                        .init(0, 0, 0),
                        .init(0, 1, 1),
                        .init(0, 1, 0)
                    ]
                ),

                // Right (x = 1)
                try! .init(
                    normal: .init(1, 0, 0),
                    vertices: [
                        .init(1, 0, 0),
                        .init(1, 1, 1),
                        .init(1, 0, 1)
                    ]
                ),
                try! .init(
                    normal: .init(1, 0, 0),
                    vertices: [
                        .init(1, 0, 0),
                        .init(1, 1, 0),
                        .init(1, 1, 1)
                    ]
                )
            ]
        )
    }
}
