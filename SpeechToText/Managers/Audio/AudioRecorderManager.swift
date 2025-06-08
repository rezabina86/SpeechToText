import Combine
import Foundation
import AVFoundation

enum AudioRecordingManagerState: Equatable {
    case idle
    case error(AudioRecorderManager.AudioError)
    case recording(audioURL: URL)
}

protocol AudioRecorderManagerType {
    var state: AnyPublisher<AudioRecordingManagerState, Never> { get }
    func requestRecordPermission() async -> Bool
    func start()
    func stop()
}

final class AudioRecorderManager: NSObject, AudioRecorderManagerType {
    
    init(audioSession: AudioSessionType,
         audioRecorderFactory: AudioRecorderFactoryType,
         fileManager: FileManagerType,
         dateProvider: DateProviderType,
         audioApplication: AudioApplicationType.Type) {
        self.audioSession = audioSession
        self.audioRecorderFactory = audioRecorderFactory
        self.fileManager = fileManager
        self.dateProvider = dateProvider
        self.audioApplication = audioApplication
        
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
    }
    
    func requestRecordPermission() async -> Bool {
        await audioApplication.requestRecordPermission()
    }
    
    // MARK: - Privates
    private let stateSubject: CurrentValueSubject<AudioRecordingManagerState, Never> = .init(.idle)
    
    private let audioSession: AudioSessionType
    
    private let audioRecorderFactory: AudioRecorderFactoryType
    private var audioRecorder: AudioRecorderType?
    
    private let fileManager: FileManagerType
    private let dateProvider: DateProviderType
    
    private let audioApplication: AudioApplicationType.Type
    
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

extension AudioRecorderManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            stateSubject.send(.idle)
        }
    }
}
