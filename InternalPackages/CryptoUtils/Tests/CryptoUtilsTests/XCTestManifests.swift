import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        return [
            testCase(CryptoUtilsTests.allTests),
        ]
    }
#endif /* !canImport(ObjectiveC) */
