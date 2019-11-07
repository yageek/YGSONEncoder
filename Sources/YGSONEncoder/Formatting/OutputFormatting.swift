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
    }

    public enum KeyEncodingStrategy {
        case convertToSnakeCase
        case useDefaultKeys
        case custom(([CodingKey]) -> CodingKey)
    }


    private class Writer {
        private(set) var buffer: String = ""

        func clear() {
            self.buffer.removeAll()
        }

        func write(_ str: String) {
            self.buffer.append(contentsOf: str)
        }
    }

    final class Formatter {
        private var topLevel: JSONType
        private var writer: Writer

        init(topLevel: JSONType) {
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

        func toJSONObject(object: [String: JSONType]) {
            writer.write("{")

            var first = true
            for (key, value) in object {
                if first {
                    first = false
                } else {
                    writer.write(",")
                }

                writer.write("\"\(key)\":")
                toJSONPrimitive(value: value)
            }
            writer.write("}\\n")
        }

        func toJSONArray(elements: [JSONType]) {
            writer.write("[")
            var first = true
            for element in elements {
                if first {
                    first = false
                } else {
                    writer.write(",")
                }
                toJSONPrimitive(value: element)
            }
            writer.write("]")
        }
    }

}
