import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ArcBottomTabBarTests.allTests),
    ]
}
#endif
