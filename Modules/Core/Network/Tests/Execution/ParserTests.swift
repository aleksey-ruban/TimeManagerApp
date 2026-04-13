import Foundation
import XCTest
@testable import CoreNetwork

final class ParserTests: XCTestCase {
    func testParserDecodesRootPayload() throws {
        let parser = Parser<TaskPayload>()
        let data = Data("{\"id\":7,\"title\":\"Focus\"}".utf8)

        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed, TaskPayload(id: 7, title: "Focus"))
    }

    func testParserDecodesNestedPayloadByRootKeyPath() throws {
        let parser = Parser<TaskPayload>(rootKeyPath: "payload.task")
        let data = Data("""
        {
          "meta": { "success": true },
          "payload": {
            "task": {
              "id": 7,
              "title": "Focus"
            }
          }
        }
        """.utf8)

        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed, TaskPayload(id: 7, title: "Focus"))
    }

    func testParserThrowsWhenRootKeyPathMissing() {
        let parser = Parser<TaskPayload>(rootKeyPath: "payload.task")
        let data = Data("{\"payload\":{}}".utf8)

        XCTAssertThrowsError(try parser.parse(data)) { error in
            XCTAssertEqual(error as? ParserError, .missingKey("payload.task"))
        }
    }
}
