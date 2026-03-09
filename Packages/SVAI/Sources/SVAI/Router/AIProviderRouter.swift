import Foundation
import SVCore

/// Routes AI requests to the appropriate provider (on-device or cloud).
/// Full implementation in Phase 2.
public final class AIProviderRouter: Sendable {
    public static let shared = AIProviderRouter()

    private init() {}

    /// Route a request to the best available AI provider.
    public func route(prompt: String) async throws -> String {
        // Phase 2: Check on-device availability, fallback to cloud
        ""
    }
}
