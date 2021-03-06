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
        case millisecondsSince1970
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

        func writeData(_ data: Data) {
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

        // See: https://stackoverflow.com/a/16254918/856142
        private let iso8601DateFormatter: DateFormatter = {
            let dateFormatter = DateFormatter()
            let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
            dateFormatter.locale = enUSPosixLocale
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            return dateFormatter

        }()
        struct Options {
            let formatting: OutputFormatting
            let dataEncoding: DataEncodingStrategy
            let dateEncoding: DateEncodingStrategy
            let keyEncoding: KeyEncodingStrategy
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

        let encoder: Encoder
        init(topLevel: JSONType, options: Options, encoder: Encoder) {
            self.options = options
            self.writer = Writer()
            self.topLevel = topLevel
            self.encoder = encoder
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
        func writeData(_ data: Data) throws {

            switch options.dataEncoding {
            case .base64:
                writer.writeData(data.base64EncodedData())
            case .custom(let op):
                try op(data, encoder)
            case .deferredToData:
                writer.writeData(data)
            }
        }

        func writeDate(_ date: Date) throws {
            switch options.dateEncoding {
            case .deferredToDate:
                try date.encode(to: self.encoder)
            case .secondsSince1970:
                let number = date.timeIntervalSince1970
                try writeJSONPrimitive(value: .float(number))
            case .millisecondsSince1970:
                let number = date.timeIntervalSince1970
                try writeJSONPrimitive(value: .float(1000.0 * number))
            case .iso8601:
                let value = iso8601DateFormatter.string(from: date)
                try writer.write(value)
            case .formatted(let formatter):
                let value = formatter.string(from: date)
                try writer.write(value)
            case .custom(let op):
                try op(date, encoder)
            }
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
                try writeData(data)
            case .array(let array):
                try writeJSONArray(elements: array)
            case .object(let object):
                try writeJSONObject(object: object)
            }
        }

        // MARK: - Dictionary

        /// See: https://github.com/apple/swift/blob/master/stdlib/public/Darwin/Foundation/JSONEncoder.swift
        func snakeCase(stringKey: String) -> String {
            guard !stringKey.isEmpty else { return stringKey }

            var words : [Range<String.Index>] = []
            // The general idea of this algorithm is to split words on transition from lower to upper case, then on transition of >1 upper case characters to lowercase
            //
            // myProperty -> my_property
            // myURLProperty -> my_url_property
            //
            // We assume, per Swift naming conventions, that the first character of the key is lowercase.
            var wordStart = stringKey.startIndex
            var searchRange = stringKey.index(after: wordStart)..<stringKey.endIndex

            // Find next uppercase character
            while let upperCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.uppercaseLetters, options: [], range: searchRange) {
                let untilUpperCase = wordStart..<upperCaseRange.lowerBound
                words.append(untilUpperCase)

                // Find next lowercase character
                searchRange = upperCaseRange.lowerBound..<searchRange.upperBound
                guard let lowerCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.lowercaseLetters, options: [], range: searchRange) else {
                    // There are no more lower case letters. Just end here.
                    wordStart = searchRange.lowerBound
                    break
                }

                // Is the next lowercase letter more than 1 after the uppercase? If so, we encountered a group of uppercase letters that we should treat as its own word
                let nextCharacterAfterCapital = stringKey.index(after: upperCaseRange.lowerBound)
                if lowerCaseRange.lowerBound == nextCharacterAfterCapital {
                    // The next character after capital is a lower case character and therefore not a word boundary.
                    // Continue searching for the next upper case for the boundary.
                    wordStart = upperCaseRange.lowerBound
                } else {
                    // There was a range of >1 capital letters. Turn those into a word, stopping at the capital before the lower case character.
                    let beforeLowerIndex = stringKey.index(before: lowerCaseRange.lowerBound)
                    words.append(upperCaseRange.lowerBound..<beforeLowerIndex)

                    // Next word starts at the capital before the lowercase we just found
                    wordStart = beforeLowerIndex
                }
                searchRange = lowerCaseRange.upperBound..<searchRange.upperBound
            }
            words.append(wordStart..<searchRange.upperBound)
            let result = words.map({ (range) in
                return stringKey[range].lowercased()
            }).joined(separator: "_")
            return result
        }

        func keyConvertion(key: String) -> String {

            switch options.keyEncoding {
            case .convertToSnakeCase:
                return keyConvertion(key: key)
            case .useDefaultKeys:
                return key
            case .custom(_):
                fatalError("Unimplemented yet")
            }
        }
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
