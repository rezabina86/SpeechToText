import Foundation

public struct UserAction {

    public init(_ action: @escaping () -> Void) {
        self.init(alwaysEqual: false, action: action)
    }

    private init(alwaysEqual: Bool, action: @escaping () -> Void) {
        self.alwaysEqual = alwaysEqual
        self.action = action
    }

    public static let fake = Self(alwaysEqual: true, action: {})
    public static let empty = Self(alwaysEqual: false, action: {})

    public let action: () -> Void

    // MARK: Private
    private let alwaysEqual: Bool
}

extension UserAction: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        [lhs.alwaysEqual, rhs.alwaysEqual].contains(true)
    }
}
