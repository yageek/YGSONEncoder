import Foundation

public class YGSONEncoder {

    enum EncodingError: Error {
        case invalidUTF8String(String)
    }

    public var dataEncodingStrategy: YGSONEncoder.DataEncodingStrategy = .base64
    public var dateEncodingStrategy: YGSONEncoder.DateEncodingStrategy = .deferredToDate
    public var keyEncodingStrategy: YGSONEncoder.KeyEncodingStrategy = .useDefaultKeys
    public var outputFormatting: YGSONEncoder.OutputFormatting = []
    
    func encode<T>(_ value: T) throws -> Data where T: Encodable {

        let encoder = _YGSONEncoder()
        try value.encode(to: encoder)

        let topLevel = encoder.jsonValue

        let options = Formatter.Options(formatting: self.outputFormatting, dataEncoding: self.dataEncodingStrategy, dateEncoding: self.dateEncodingStrategy, keyEncoding: self.keyEncodingStrategy)
        let formatter = Formatter(topLevel: topLevel, options: options, encoder: encoder)
        return try formatter.writeJSON()
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
