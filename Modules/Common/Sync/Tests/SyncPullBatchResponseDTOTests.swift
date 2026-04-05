import Domain
import Foundation
import XCTest
@testable import CommonSync

final class SyncPullBatchResponseDTOTests: XCTestCase {
    func testDecodingPullEnvelopeSplitsObjectsAndComputesMaxSnapshotVersion() throws {
        let json = """
        {
          "message": "Data sent",
          "data": {
            "objects": [
              {
                "type": "CATEGORY",
                "payload": {
                  "id": 5,
                  "lastModifiedVersion": 4,
                  "name": "Gym",
                  "code": "WORKOUT",
                  "deleted": false
                }
              },
              {
                "type": "ACTIVITY",
                "payload": {
                  "id": 8,
                  "lastModifiedVersion": 12,
                  "name": "iOS app",
                  "categoryId": 5,
                  "icon": "hammer.fill",
                  "iconColor": "GREEN",
                  "variations": [],
                  "deleted": false
                }
              },
              {
                "type": "ACTIVITY_RECORD",
                "payload": {
                  "id": 11,
                  "lastModifiedVersion": 9,
                  "activityId": 8,
                  "variationId": null,
                  "startedAt": "2026-02-03T07:00:00Z",
                  "endedAt": "2026-02-03T10:30:00Z",
                  "timeZone": "Europe/Moscow",
                  "deleted": false
                }
              }
            ],
            "nextCursor": "cursor-2",
            "hasMore": true
          }
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let response = try decoder.decode(SyncPullBatchResponseDTO.self, from: Data(json.utf8))

        XCTAssertEqual(response.categories.count, 1)
        XCTAssertEqual(response.activities.count, 1)
        XCTAssertEqual(response.activityRecords.count, 1)
        XCTAssertEqual(response.chronometries.count, 0)
        XCTAssertEqual(response.nextCursor, "cursor-2")
        XCTAssertTrue(response.hasMore)
        XCTAssertEqual(response.maxSnapshotVersion, SnapshotVersion(Int64(12)))
    }
}
