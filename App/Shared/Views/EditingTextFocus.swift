import SwiftUI

private struct EditingRoutineTextKey: FocusedValueKey { typealias Value = Bool }
extension FocusedValues {
    var editingRoutineText: Bool? {
        get { self[EditingRoutineTextKey.self] }
        set { self[EditingRoutineTextKey.self] = newValue }
    }
}
