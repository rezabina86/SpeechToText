import Combine
import Foundation
import AVFoundation

enum AudioRecordingManagerState: Equatable {
    case idle
    case error(AudioRecordingManager.AudioError)
    case recording(audioURL: URL)
}

protocol AudioRecordingManagerType {
    var state: AnyPublisher<AudioRecordingManagerState, Never> { get }
    func start()
    func stop()
}

final class AudioRecordingManager: NSObject, AudioRecordingManagerType {
    
    init(audioSession: AudioSessionType,
         audioRecorderFactory: AudioRecorderFactoryType,
         fileManager: FileManagerType,
         dateProvider: DateProviderType) {
        self.audioSession = audioSession
        self.audioRecorderFactory = audioRecorderFactory
        self.fileManager = fileManager
        self.dateProvider = dateProvider
        
        super.init()
        setupAudioSession()
    }
    
    var state: AnyPublisher<AudioRecordingManagerState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    func start() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("recording_\(dateProvider.timeIntervalSince1970).m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try audioRecorderFactory.createRecorder(url: audioURL, settings: settings)
        } catch {
            stateSubject.send(.error(.recordingFailed))
            return
        }
        
        audioRecorder?.delegate = self
        
        guard audioRecorder?.record() == true else {
            stateSubject.send(.error(.recordingFailed))
            return
        }
        
        stateSubject.send(.recording(audioURL: audioURL))
    }
    
    func stop() {
        audioRecorder?.stop()
        audioRecorder = nil
    }
    
    
    // MARK: - Privates
    private let stateSubject: CurrentValueSubject<AudioRecordingManagerState, Never> = .init(.idle)
    
    private let audioSession: AudioSessionType
    
    private let audioRecorderFactory: AudioRecorderFactoryType
    private var audioRecorder: AudioRecorderType?
    
    private let fileManager: FileManagerType
    private let dateProvider: DateProviderType
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord,
                                         mode: .default,
                                         options: [.defaultToSpeaker, .allowBluetooth, .duckOthers])
            try audioSession.setActive(true, options: [])
        } catch {
            fatalError("Failed to setup audio session: \(error)")
        }
    }
    
    enum AudioError: Error {
        case recordingFailed
    }
}

extension AudioRecordingManager: AVAudioRecorderDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stateSubject.send(.idle)
    }
}
