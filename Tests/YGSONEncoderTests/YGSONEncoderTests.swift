import XCTest
@testable import YGSONEncoder

final class YGSONEncoderTests: XCTestCase {
    struct TestValue: Encodable {
        let a: String
        let b: Int
        let c: TestEmbedded
    }

    struct TestEmbedded: Encodable {
        let a: [String]
        let b: [Int]
    }

    func testObject() {
        let object = TestEmbedded(a: ["1", "2", "3"], b: [4, 5, 6, 7, 8])

        let encoder = YGSONEncoder()

        var value: String! = nil

        // Not formatted
        XCTAssertNoThrow(value = try encoder.encodeString(object))
        XCTAssertEqual(#"{"a":["1","2","3"],"b":[4,5,6,7,8]}\n"#, value)

        // Formatted
        encoder.outputFormatting = [.prettyPrinted]
        XCTAssertNoThrow(value = try encoder.encodeString(object))
        print("Value: \(value!)")
        XCTAssertEqual(#"{"a":["1","2","3"],"b":[4,5,6,7,8]}\n"#, value)

    }

    static var allTests = [
        ("testExample", testObject),
    ]
}
