import Domain
import Foundation
import XCTest

final class SnapshotVersionTests: XCTestCase {
    func testDecodesFromStringAndComparesCorrectly() throws {
        let data = Data(#""12345678901234567890""#.utf8)
        let version = try JSONDecoder().decode(SnapshotVersion.self, from: data)

        XCTAssertEqual(version, SnapshotVersion(Decimal(string: "12345678901234567890")!))
        XCTAssertTrue(version > SnapshotVersion(Int64(1)))
    }

    func testDecodesFromNumberAndEncodesBack() throws {
        let version = try JSONDecoder().decode(SnapshotVersion.self, from: Data("42".utf8))
        let encoded = try JSONEncoder().encode(version)

        XCTAssertEqual(version, SnapshotVersion(Int64(42)))
        XCTAssertEqual(String(decoding: encoded, as: UTF8.self), "42")
    }
}
