import CoreSync
import Domain
import Foundation
import XCTest
@testable import CommonSync

final class ServerPullBatchSourceTests: XCTestCase {
    func testFetchBatchMapsObjectsToStageChangesAndTracksMaxSnapshotVersion() async throws {
        let responseJSON = """
        {
          "message": "Data sent",
          "data": {
            "objects": [
              {
                "type": "CATEGORY",
                "payload": {
                  "id": 1,
                  "lastModifiedVersion": 4,
                  "name": "Gym",
                  "code": "WORKOUT",
                  "deleted": false
                }
              },
              {
                "type": "ACTIVITY",
                "payload": {
                  "id": 2,
                  "lastModifiedVersion": 8,
                  "name": "Workout",
                  "categoryId": 1,
                  "icon": "figure.run",
                  "iconColor": "GREEN",
                  "variations": [],
                  "deleted": false
                }
              }
            ],
            "nextCursor": "next",
            "hasMore": true
          }
        }
        """
        let remoteAPI = SyncRemoteAPIStub(
            fetchPullBatchHandler: { cursor, clientSnapshotVersion in
                XCTAssertNil(cursor)
                XCTAssertEqual(clientSnapshotVersion, SnapshotVersion(Int64(3)))
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(SyncPullBatchResponseDTO.self, from: Data(responseJSON.utf8))
            }
        )
        let source = ServerPullBatchSource(
            remoteAPI: remoteAPI,
            clientSnapshotVersion: SnapshotVersion(Int64(3))
        )

        let batch = try await source.fetchBatch(after: Optional<String>.none)

        XCTAssertEqual(batch?.changes.count, 2)
        XCTAssertEqual(batch?.nextCursor, "next")
        XCTAssertEqual(batch?.changes.map { $0.stageID }, [CommonSyncStageIDs.categories, CommonSyncStageIDs.activities])
        XCTAssertEqual(source.maxSnapshotVersion, SnapshotVersion(Int64(8)))
    }

    func testFetchBatchReturnsNilForTerminalEmptyResponse() async throws {
        let responseJSON = """
        {
          "message": "Data sent",
          "data": {
            "objects": [],
            "nextCursor": null,
            "hasMore": false
          }
        }
        """
        let remoteAPI = SyncRemoteAPIStub(
            fetchPullBatchHandler: { _, _ in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(SyncPullBatchResponseDTO.self, from: Data(responseJSON.utf8))
            }
        )
        let source = ServerPullBatchSource(
            remoteAPI: remoteAPI,
            clientSnapshotVersion: .zero
        )

        let batch = try await source.fetchBatch(after: Optional<String>.none)

        XCTAssertNil(batch)
        XCTAssertEqual(source.maxSnapshotVersion, SnapshotVersion.zero)
    }
}
