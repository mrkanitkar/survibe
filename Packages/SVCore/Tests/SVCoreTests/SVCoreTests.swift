import Testing

@testable import SVCore

struct SVCoreTests {
    @Test("SVCore re-exports Foundation types")
    func foundationReExported() {
        // @_exported import Foundation in SVCore.swift means downstream
        // packages get Foundation automatically. Verify key types resolve.
        let _: UUID = UUID()
        let _: Date = Date()
        let _: URL? = URL(string: "https://survibe.app")
        // If Foundation wasn't re-exported, this file would fail to compile
        // since we only import SVCore, not Foundation explicitly.
    }

    @Test("SVCore version is semantic version format")
    func versionIsSemanticFormat() {
        let components = SVCore.version.split(separator: ".")
        #expect(components.count == 3, "Version should be major.minor.patch")
        for component in components {
            #expect(Int(component) != nil, "'\(component)' is not a number")
        }
    }
}
