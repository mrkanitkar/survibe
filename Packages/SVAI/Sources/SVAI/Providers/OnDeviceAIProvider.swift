import Foundation

/// On-device AI provider using Apple's FoundationModels framework.
/// Full implementation in Phase 2.
public final class OnDeviceAIProvider: AIProvider {
    public let name = "On-Device"

    public init() {}

    public var isAvailable: Bool {
        // Phase 2: Check FoundationModels availability
        false
    }

    public func generate(prompt: String) async throws -> String {
        // Phase 2: Use FoundationModels for on-device inference
        ""
    }
}
