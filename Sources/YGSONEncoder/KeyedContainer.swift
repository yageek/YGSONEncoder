//
//  KeyedContainer.swift
//  
//
//  Created by Yannick Heinrich on 04.11.19.
//

import Foundation

extension _YGSONEncoder {

    fileprivate class Storage<Key: CodingKey> {

        typealias KeyValue = (Key, YGSONEncodingContainer)
        private(set) var elements: [KeyValue] = []
        private var hash: [String: KeyValue] = [:]

        func append(key: Key, value: YGSONEncodingContainer) {
            let keyValue: KeyValue = (key, value)
            self.elements.append(keyValue)
            self.hash[key.stringValue] = keyValue
        }
    }

    class KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {

        private(set) var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]

        private var storage = Storage<Key>()

        func nestedCodingPath(forKey key: CodingKey) -> [CodingKey] {
            return self.codingPath + [key]
        }

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
        }

        // MARK: - KeyedEncodingContainerProtocol
        func encodeNil(forKey key: Key) throws {
            var container = self.nestedSingleValueContainer(forKey: key)
            try container.encodeNil()
        }

        func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            var container = self.nestedSingleValueContainer(forKey: key)
            try container.encode(value)
        }

        private func nestedSingleValueContainer(forKey key: Key) -> SingleValueEncodingContainer {
            let container = _YGSONEncoder.SingleValueContainer(codingPath: self.nestedCodingPath(forKey: key), userInfo: self.userInfo)
            self.storage.append(key: key, value: container)
            return container
        }


         func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            let container = _YGSONEncoder.UnkeyedContainer(codingPath: self.nestedCodingPath(forKey: key), userInfo: self.userInfo)
            self.storage.append(key: key, value: container)

            return container
        }

        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            let container = _YGSONEncoder.KeyedContainer<NestedKey>(codingPath: self.nestedCodingPath(forKey: key), userInfo: self.userInfo)
            self.storage.append(key: key, value: container)

            return KeyedEncodingContainer(container)
        }

        func superEncoder() -> Encoder {
            fatalError("Unimplemented")
        }

        func superEncoder(forKey key: Key) -> Encoder {
            fatalError("Unimplemented")
        }
    }

}

extension _YGSONEncoder.KeyedContainer: YGSONEncodingContainer {

    var jsonValue: JSONType {
        let elements = self.storage.elements.map { ($0.0.stringValue, $0.1.jsonValue) }
        return .object(elements)
    }
}
