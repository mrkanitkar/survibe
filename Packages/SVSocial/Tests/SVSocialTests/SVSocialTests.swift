import Testing

@testable import SVSocial

@Suite("SVSocial Module Tests")
struct SVSocialModuleTests {
    @Test("SVSocial version is semantic version format")
    func versionIsSemanticFormat() {
        let components = SVSocial.version.split(separator: ".")
        #expect(components.count == 3)
        for component in components {
            #expect(Int(component) != nil)
        }
    }
}
