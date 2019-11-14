import XCTest
@testable import YGSONEncoder

final class YGSONEncoderTests: XCTestCase {

    var encoder: YGSONEncoder!

    override func setUp() {
        super.setUp()
        encoder = YGSONEncoder()
    }

    struct TestValue: Encodable {
        let a: String
        let b: Int
        let c: TestEmbedded
    }

    struct TestEmbedded: Encodable {
        let a: [String]
        let b: [Int]
    }

    func testFormattingAndPrettyPrinted() {
        let object = TestEmbedded(a: ["1", "2", "3"], b: [4, 5, 6, 7, 8])
        var value: Data! = nil

        // Not formatted
        XCTAssertNoThrow(value = try encoder.encode(object))
        XCTAssertEqual(#"{"a":["1","2","3"],"b":[4,5,6,7,8]}"#, String(data: value, encoding: .utf8))

        // Formatted
        encoder.outputFormatting = [.prettyPrinted]
        XCTAssertNoThrow(value = try encoder.encode(object))
        let expectedPrettyPrinted = """
{
    "a": [
        "1",
        "2",
        "3"
    ],
    "b": [
        4,
        5,
        6,
        7,
        8
    ]
}
"""
        XCTAssertEqual(expectedPrettyPrinted, String(data: value, encoding: .utf8))
    }

    struct TestUnsortedStruct: Codable {
        let z: String
        let b: String
        let r: String
        let c: String
    }

    func testSortedKeys() {
        let element = TestUnsortedStruct(z: "1", b: "2", r: "3", c: "4")

        encoder.outputFormatting = [.sortedKeys]
        let value = try! encoder.encode(element)
        XCTAssertEqual(#"{"b":"2","c":"4","r":"3","z":"1"}"#, String(data: value, encoding: .utf8))
    }

    static var allTests = [
        ("testFormattingAndPrettyPrinted", testFormattingAndPrettyPrinted),
        ("testSortedKeys", testSortedKeys)
    ]
}
