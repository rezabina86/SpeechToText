import Foundation
import AVFoundation

protocol AudioPlayerFactoryFactoryType {
    func createPlayer(contentsOf url: URL) throws -> AudioPlayerType
}

struct AudioPlayerFactoryFactory: AudioPlayerFactoryFactoryType {
    func createPlayer(contentsOf url: URL) throws -> AudioPlayerType {
        try AVAudioPlayer(contentsOf: url)
    }
}

protocol AudioPlayerType {
    var delegate: AVAudioPlayerDelegate? { get set }
    var currentTime: TimeInterval { get }
    var isPlaying: Bool { get }
    @discardableResult func play() -> Bool
    func stop()
}

extension AVAudioPlayer: AudioPlayerType {}
