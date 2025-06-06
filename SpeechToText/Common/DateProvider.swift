import Foundation

protocol DateProviderType {
    var timeIntervalSince1970: TimeInterval { get }
}

class DateProvider: DateProviderType {
    var timeIntervalSince1970: TimeInterval {
        Date.now.timeIntervalSince1970
    }
}
