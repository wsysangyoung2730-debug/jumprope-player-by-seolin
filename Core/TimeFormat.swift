import Foundation
public func timeText(_ seconds: Double, precise: Bool = false) -> String {
    let value = seconds.isFinite ? min(31_536_000, max(0, seconds)) : 0
    return precise ? String(format: "%d:%04.1f", Int(value) / 60, value.truncatingRemainder(dividingBy: 60)) : String(format: "%d:%02d", Int(value) / 60, Int(value) % 60)
}
