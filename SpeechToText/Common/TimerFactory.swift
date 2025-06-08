import Combine
import Foundation

protocol TimerFactoryType {
    func makeTimer(interval: TimeInterval) -> AnyPublisher<Date, Never>
}

final class TimerFactory: TimerFactoryType {
    func makeTimer(interval: TimeInterval) -> AnyPublisher<Date, Never> {
        Timer
            .publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .eraseToAnyPublisher()
    }
}
