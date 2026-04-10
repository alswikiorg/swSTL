//
//  swSTL.swift
//  swSTL
//
//  Created by Craig Reyenga on 2026-04-10.
//

import ArgumentParser
import Foundation
import swSTLCore

@main
struct swSTL: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swstl",
        abstract: "STL utilities",
        subcommands: [
            InfoCommand.self,
            ConvertCommand.self,
            VersionCommand.self
        ]
    )
}

fileprivate struct InfoCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "info",
        abstract: "Query an STL file"
    )

    @Argument(help: "Input STL file")
    var input: String

    mutating func run() throws {
        let fm = FileManager.default

        // Input validation
        guard fm.fileExists(atPath: input) else {
            throw ValidationError("Input file does not exist: \(input)")
        }

        let src = try Data(contentsOf: URL(fileURLWithPath: input))
        let inStl = try STLCoder.decode(src)

        let fileSize = src.count
        let fileName = URL(fileURLWithPath: input).lastPathComponent

        print("STL file: \(fileName)")
        print("File size: \(fileSize) bytes")
        print("Format: \(inStl.header.description)")
        print("Facets: \(inStl.facets.count)")
    }
}

fileprivate struct ConvertCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "convert",
        abstract: "Convert an STL file"
    )

    @Option(name: [.customShort("s"), .long], help: "Scale (e.g. 5:4 or 1.25)")
    var scale: Scale = .unit

    @Option(name: [.customShort("n"), .long], help: "STL internal name, defaults to name from input file if present, otherwise blank")
    var name: String? = nil

    @Option(name: .shortAndLong, help: "Output format ((a)scii or (b)inary)")
    var outputFormat: STLFormat = .ascii

    @Flag(name: [.customShort("F"), .long], help: "Overwrite output file if it exists")
    var force: Bool = false

    @Argument(help: "Input STL file")
    var input: String

    @Argument(help: "Output STL file")
    var output: String

    mutating func run() throws {
        let fm = FileManager.default

        // Input validation
        guard fm.fileExists(atPath: input) else {
            throw ValidationError("Input file does not exist: \(input)")
        }

        // Output validation
        let outputDir = (output as NSString).deletingLastPathComponent
        if !outputDir.isEmpty && !fm.fileExists(atPath: outputDir) {
            throw ValidationError("Output directory does not exist: \(outputDir)")
        }

        // Overwrite protection
        if fm.fileExists(atPath: output) && !force {
            throw ValidationError(
                "Output file already exists: \(output)\nUse --force to overwrite."
            )
        }

        let src = try Data(contentsOf: URL(fileURLWithPath: input))
        let inStl = try STLCoder.decode(src)

        let outStl = (scale == .unit) ? inStl : try inStl.scaled(by: scale.value)

        let dst = try STLCoder.encode(outStl, outputFormat: outputFormat, overrideName: name)
        try dst.write(to: URL(fileURLWithPath: output))
    }
}

fileprivate struct VersionCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "App Version"
    )

    mutating func run() throws {
        print("\(APP_NAME) \(APP_VERSION)")
    }
}

// MARK: - Scale type

fileprivate struct Scale: ExpressibleByArgument, Equatable, CustomStringConvertible {
    let value: Float32

    init(value: Float32) {
        precondition(value > 0)
        self.value = value
    }

    public init?(argument: String) {
        if argument.contains(":") {
            let parts = argument.split(separator: ":")
            guard parts.count == 2,
                  let a = Float32(parts[0]),
                  let b = Float32(parts[1]),
                  a > 0,
                  b > 0 else { return nil }
            self.value = a / b
        } else if let v = Float32(argument), v > 0 {
            self.value = v
        } else {
            return nil
        }
    }

    static var unit: Scale {
        .init(value: 1)
    }

    var description: String {
        String(describing: value)
    }
}

// MARK: - Format arg

extension STLFormat: ExpressibleByArgument {
    public init?(argument: String) {
        switch argument.lowercased() {
        case "ascii", "a":
            self = .ascii
        case "binary", "b":
            self = .binary
        default:
            return nil
        }
    }
}
