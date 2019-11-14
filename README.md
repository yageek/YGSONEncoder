# YGSONEncoder

A reimplementation of JSONEncoder to have `sortedKeys` on pre-iOS 11 (not based on `JSONSerialization`).

Code largely inspired by: 

- [apple/swift](https://github.com/apple/swift) for snakeCaseConversion
- [apple/swift-corelibs-foundation](https://github.com/apple/swift-corelibs-foundation) for pretty printing

## Current features
- [X] `DateEncodingStrategy`
- [X] `DataEncodingStrategy`
- [X] `OutputFormatting`
- [ ] `KeyEncodingStrategy`
- [ ] `JSONEncoder.NonConformingFloatEncodingStrategy`
- [ ] Class inheritance encoding

## Usage
```swift 
struct TestUnsortedStruct: Codable {
       let z: String
       let b: String
       let r: String
       let c: String
}

let element = TestUnsortedStruct(z: "1", b: "2", r: "3", c: "4")
let encoder = YGSONEncoder()
encoder.outputFormatting = [.sortedKey]

do {
    let data = try encoder.encode(element)
    } catch let error {
        print("Error: \(error)")
}
```
