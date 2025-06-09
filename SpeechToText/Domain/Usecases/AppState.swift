import Foundation

enum AppState: Equatable {
    case idle
    case recording
    case readyToPlay
    case playing
    case error(String)
}
