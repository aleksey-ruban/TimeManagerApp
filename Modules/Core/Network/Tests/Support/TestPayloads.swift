import Foundation

struct TaskPayload: Decodable, Equatable {
    let id: Int
    let title: String
}

struct EmptyPayload: Decodable, Equatable {}
