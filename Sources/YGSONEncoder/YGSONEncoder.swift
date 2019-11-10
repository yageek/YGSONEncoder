import Foundation

public class YGSONEncoder {

    enum EncodingError: Error {
        case utf8Conversion
    }

    public var dataEncodingStrategy: YGSONEncoder.DataEncodingStrategy = .base64
    public var dateEncodingStrategy: YGSONEncoder.DateEncodingStrategy = .deferredToDate
    public var keyEncodingStrategy: YGSONEncoder.KeyEncodingStrategy = .useDefaultKeys
    public var outputFormatting: YGSONEncoder.OutputFormatting = []
    
    func encodeString<T>(_ value: T) throws -> String where T: Encodable {

        let encoder = _YGSONEncoder()
        try value.encode(to: encoder)

        let topLevel = encoder.jsonValue

        let formatter = Formatter(topLevel: topLevel, options: Formatter.Options(formatting: self.outputFormatting))
        return formatter.toJSON()
    }

    public func encode<T>(_ value: T) throws -> Data where T: Encodable {
        let string: String = try encodeString(value)

        guard let data = string.data(using: .utf8) else { throw EncodingError.utf8Conversion }
        return data
    }
}

protocol YGSONEncodingContainer {
    var jsonValue: JSONType { get }
}

class _YGSONEncoder: Encoder {
    var codingPath: [CodingKey] = []

    var userInfo: [CodingUserInfoKey : Any] = [:]
     fileprivate var container: YGSONEncodingContainer?

    fileprivate func assertCanCreateContainer() {
        precondition(self.container == nil)
    }

    var jsonValue: JSONType {
        return container?.jsonValue ?? .null
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        assertCanCreateContainer()

        let container = KeyedContainer<Key>(codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container

        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        assertCanCreateContainer()

        let container = UnkeyedContainer(codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container

        return container
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        assertCanCreateContainer()

        let container = SingleValueContainer(codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container

        return container
    }

}
