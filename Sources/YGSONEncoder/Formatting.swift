//
//  JSONTypeFormatter.swift
//  
//
//  Created by Yannick Heinrich on 05.11.19.
//

import Foundation


extension YGSONEncoder {

    public struct OutputFormatting: OptionSet {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        static let prettyPrinted = OutputFormatting(rawValue: 1 << 0)
        static let sortedKeys = OutputFormatting(rawValue: 1 << 1)
    }

    public enum DateEncodingStrategy {
        case deferredToDate
        case secondsSince1970
        case iso8601
        case formatted(DateFormatter)
        case custom((Date, Encoder) throws -> Void)
    }

    public enum DataEncodingStrategy {
        case base64
        case custom((Data, Encoder) throws -> Void)
        case deferredToData

        fileprivate func encode(data: Data) -> String {

            switch self {
            case .base64:
                return data.base64EncodedString()
            case .custom(_):
                return ""
            case .deferredToData:
                return ""
            }
        }
    }

    public enum KeyEncodingStrategy {
        case convertToSnakeCase
        case useDefaultKeys
        case custom(([CodingKey]) -> CodingKey)
    }

    private class Writer {

        private static let IndentationData: Data = {
            let data = "    ".data(using: .utf8)!
            return data
        }()
        private var indentationLevel: UInt = 0
        private(set) var buffer = Data()

        func clear() {
            buffer.removeAll()
        }

        func write(_ str: String) throws {
            guard let data = str.data(using: .utf8) else { throw EncodingError.invalidUTF8String(str) }
            buffer.append(data)
        }

        func deincrement() {
            indentationLevel -= 1
        }

        func increment() {
            indentationLevel += 1
        }

        func writeIndent() {
            for _ in 0..<indentationLevel {
                buffer.append(Writer.IndentationData)
            }
        }
    }

    final class Formatter {

        struct Options {
            let formatting: OutputFormatting
            let dataEncoding: DataEncodingStrategy
        }

        private var topLevel: JSONType
        private var writer: Writer
        private var options: Options

        private var prettyPrinted: Bool {
            return options.formatting.contains(.prettyPrinted)
        }

        private var sortedKeys: Bool {
            return options.formatting.contains(.sortedKeys)
        }

        init(topLevel: JSONType, options: Options) {
            self.options = options
            self.writer = Writer()
            self.topLevel = topLevel
        }

        func writeJSON() throws -> Data {
            self.writer.clear()
            switch topLevel {
            case .array(let elements):
                try writeJSONArray(elements: elements)
            case .object(let object):
                try writeJSONObject(object: object)
                break
            default:
                try writeJSONPrimitive(value: topLevel)
            }

            return writer.buffer
        }

        // MARK: - Primitives
        func writeData(_ data: Data) {

        }

        func writeJSONPrimitive(value: JSONType) throws {
            switch value {
            case .bool(let value):
                let str = value ? "true": "false"
                try writer.write(str)
            case .integer(let value):
                try writer.write("\(value)")
            case .float(let value):
                try writer.write("\(value)")
            case .string(let value):
                try writer.write("\"\(value)\"")
            case .null:
                try writer.write("null")
            case .date(let value):
                try writer.write("\(value)")
            case .data(let data):
                writeData(data)
            case .array(let array):
                try writeJSONArray(elements: array)
            case .object(let object):
                try writeJSONObject(object: object)
            }
        }

        // MARK: - Dictionary
        func writeJSONObject(object: [KeyValue]) throws {
            try writer.write("{")

            if prettyPrinted {
                try writer.write("\n")
                writer.increment()
                writer.writeIndent()
            }

            var first = true
            func writeKeyValue(key: String, value: JSONType) throws {
                if first {
                    first = false
                } else if prettyPrinted {
                    try writer.write(",\n")
                    writer.writeIndent()
                } else {
                    try writer.write(",")
                }

                if prettyPrinted {
                    try writer.write("\"\(key)\": ")
                } else {
                    try writer.write("\"\(key)\":")
                }

                try writeJSONPrimitive(value: value)
            }


            if sortedKeys {
                let elements = object.sorted { (a, b) -> Bool in
                    let a = a.0
                    let b = b.0
                    return a.compare(b, options: [.numeric, .caseInsensitive, .forcedOrdering], range: a.startIndex..<a.endIndex) == .orderedAscending
                }
                for (key, value) in elements {
                    try writeKeyValue(key: key, value: value)
                }
            } else {
                for (key, value) in object {
                    try writeKeyValue(key: key, value: value)
                }
            }


            if prettyPrinted {
                try writer.write("\n")
                writer.deincrement()
                writer.writeIndent()
            }

            try writer.write("}")
        }

        // MARK: - Array
        func writeJSONArray(elements: [JSONType]) throws {
            try writer.write("[")

            if prettyPrinted {
                try writer.write("\n")
                writer.increment()
                writer.writeIndent()
            }

            var first = true
            for element in elements {
                if first {
                    first = false
                } else if prettyPrinted {
                    try writer.write(",\n")
                    writer.writeIndent()
                } else {
                    try writer.write(",")
                }

                try writeJSONPrimitive(value: element)
            }

            if prettyPrinted {
                try writer.write("\n")
                writer.deincrement()
                writer.writeIndent()
            }
            try writer.write("]")
        }

    }
}
