import Foundation

/// Protocol for daily practice entries (additive-only design).
public protocol RiyazEntryProtocol: Sendable {
    var id: UUID { get }
    var date: Date { get }
    var minutesPracticed: Int { get }
    var accuracy: Double { get }
}
