import Foundation

@MainActor
func flushMainActor(times: Int = 5) async {
    for _ in 0..<times {
        await Task.yield()
    }
}
