import Combine
import Foundation
import AVFoundation

enum AudioPlayerManagerState: Equatable {
    case idle
    case error(AudioPlayerManager.AudioError)
    case playing(playbackTime: TimeInterval)
}

protocol AudioPlayerManagerType {
    var state: AnyPublisher<AudioPlayerManagerState, Never> { get }
    func play(audioURL: URL)
    func stop()
}

final class AudioPlayerManager: NSObject, AudioPlayerManagerType {
    
    init(audioPlayerFactoryFactory: AudioPlayerFactoryFactoryType,
         timerFactory: TimerFactoryType) {
        self.audioPlayerFactoryFactory = audioPlayerFactoryFactory
        self.timerFactory = timerFactory
    }
    
    var state: AnyPublisher<AudioPlayerManagerState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    func play(audioURL: URL) {
        do {
            audioPlayer = try audioPlayerFactoryFactory.createPlayer(contentsOf: audioURL)
        } catch {
            stateSubject.send(.error(.playbackFailed))
        }
        audioPlayer?.delegate = self
        audioPlayer?.play()
        stateSubject.send(.playing(playbackTime: 0))
        startPlaybackTimer()
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.delegate = nil
        audioPlayer = nil
        stopPlaybackTimer()
    }
    
    
    // MARK: - Privates
    private let stateSubject: CurrentValueSubject<AudioPlayerManagerState, Never> = .init(.idle)
    private var timerCancelable: AnyCancellable?
    
    private let audioPlayerFactoryFactory: AudioPlayerFactoryFactoryType
    private var audioPlayer: AudioPlayerType?
    
    private let timerFactory: TimerFactoryType
    
    private func startPlaybackTimer() {
        timerCancelable = timerFactory.makeTimer(interval: 0.1)
            .sink { [weak self] _ in
                guard let self else { return }
                let currentTime = audioPlayer?.currentTime ?? 0
                self.stateSubject.send(.playing(playbackTime: currentTime))
            }
    }
    
    private func stopPlaybackTimer() {
        timerCancelable?.cancel()
    }
    
    enum AudioError: Error {
        case playbackFailed
    }
}

extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stateSubject.send(.idle)
    }
}
