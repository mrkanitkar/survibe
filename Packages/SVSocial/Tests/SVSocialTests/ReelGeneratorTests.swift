import Testing
@testable import SVSocial

@Suite("ReelGenerator Tests")
struct ReelGeneratorTests {
    @Test("ReelGenerator initializes")
    func testInit() {
        let generator = ReelGenerator()
        #expect(generator != nil)
    }
}
