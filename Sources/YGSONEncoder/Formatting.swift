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

        private static let IndentationString: String = "    "
        private var indentationLevel: UInt = 0
        private(set) var buffer: String = ""

        func clear() {
            self.buffer.removeAll()
        }

        func write(_ str: String) {
            self.buffer.append(contentsOf: str)
        }

        func deincrement() {
            self.indentationLevel -= 1
        }

        func increment() {
            self.indentationLevel += 1
        }

        func writeIndent() {
            for _ in 0..<indentationLevel {
                self.buffer.append(Writer.IndentationString)
            }
        }
    }

    final class Formatter {

        struct Options {
            let formatting: OutputFormatting
        }

        private var topLevel: JSONType
        private var writer: Writer
        private var options: Options

        private var prettyPrinted: Bool {
            return self.options.formatting == .prettyPrinted
        }

        init(topLevel: JSONType, options: Options) {
            self.options = options
            self.writer = Writer()
            self.topLevel = topLevel
        }

        func toJSON() -> String {
            self.writer.clear()
            switch self.topLevel {
            case .array(let elements):
                self.toJSONArray(elements: elements)
            case .object(let object):
                self.toJSONObject(object: object)
                break
            default:
                self.toJSONPrimitive(value: self.topLevel)
            }

            return self.writer.buffer
        }

        func toJSONPrimitive(value: JSONType) {
            switch value {
            case .bool(let value):
                let str = value ? "true": "false"
                writer.write(str)
            case .integer(let value):
                writer.write("\(value)")
            case .float(let value):
                writer.write("\(value)")
            case .string(let value):
                writer.write("\"\(value)\"")
            case .null:
                writer.write("null")
            case .date(let value):
                writer.write("\(value)")
            case .data(_):
                break
            case .array(let array):
                self.toJSONArray(elements: array)
            case .object(let object):
                self.toJSONObject(object: object)
            }
        }

        func toJSONObject(object: [KeyValue]) {
            writer.write("{")

            if prettyPrinted {
                writer.write("\n")
                writer.increment()
                writer.writeIndent()
            }

            var first = true
            for (key, value) in object {
                if first {
                    first = false
                } else if prettyPrinted {
                    writer.write(",\n")
                    writer.writeIndent()
                } else {
                    writer.write(",")
                }

                if prettyPrinted {
                    writer.write("\"\(key)\": ")
                } else {
                    writer.write("\"\(key)\":")
                }

                toJSONPrimitive(value: value)
            }

            if prettyPrinted {
                writer.write("\n")
                writer.deincrement()
                writer.writeIndent()
            }

            writer.write("}")
        }

        func toJSONArray(elements: [JSONType]) {
            writer.write("[")

            if prettyPrinted {
                writer.write("\n")
                writer.increment()
                writer.writeIndent()
            }

            var first = true
            for element in elements {
                if first {
                    first = false
                } else if prettyPrinted {
                    writer.write(",\n")
                    writer.writeIndent()
                } else {
                    writer.write(",")
                }

                toJSONPrimitive(value: element)
            }

            if prettyPrinted {
                writer.write("\n")
                writer.deincrement()
                writer.writeIndent()
            }
            writer.write("]")
        }
    }
}
