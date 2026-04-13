import Foundation

struct APIResponse<Payload: Decodable>: Decodable {
    let message: String?
    let data: Payload?
}
