import Testing
import Foundation
@testable import BigDockLocker

struct DisplayManagerTests {
    @Test func testGetAllDisplaysReturnsAtLeastOneDisplay() async throws {
        let manager = DisplayManager()
        let displays = try manager.getAllDisplays()
        #expect(!displays.isEmpty)
    }
}
