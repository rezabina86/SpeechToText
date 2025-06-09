import Combine
import Foundation

enum SpeechRecognitionState: Equatable {
    case idle
    case recording(result: TranscriptionResult?)
    case readyToPlay(result: TranscriptionResult)
    case playing(result: TranscriptionResult, highlightedWordIndex: Int)
    case error(String)
}

protocol SpeechRecognitionUseCaseType {
    var state: AnyPublisher<SpeechRecognitionState, Never> { get }
    
    func startRecording()
    func stopRecording()
    func startPlayback()
    func stopPlayback()
    func reset()
}

final class SpeechRecognitionUseCase: SpeechRecognitionUseCaseType {
    
    init(
        audioPlayerManager: AudioPlayerManagerType,
        audioRecorderManager: AudioRecorderManagerType,
        speechRecognitionManager: SpeechRecognitionManagerType
    ) {
        self.audioPlayerManager = audioPlayerManager
        self.audioRecorderManager = audioRecorderManager
        self.speechRecognitionManager = speechRecognitionManager
        
        subscribeToAudioPlayerManager()
        subscribeToAudioRecorderManager()
        subscribeToSpeechRecognitionManager()
        
        createObservableState()
    }
    
    var state: AnyPublisher<SpeechRecognitionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    func startRecording() {
        Task {
            let audioPermission = await audioRecorderManager.requestRecordPermission()
            let speechPermission = await speechRecognitionManager.requestPermissions()
            
            guard audioPermission && speechPermission else {
                print("Not authorized!")
                return
            }
            
            audioRecorderManager.start()
            speechRecognitionManager.start()
            appState.send(.recording)
        }
    }
    
    func stopRecording() {
        speechRecognitionManager.stop()
        audioRecorderManager.stop()
    }
    
    func startPlayback() {
        guard let recordingURL else {
            return
        }
        
        audioPlayerManager.play(audioURL: recordingURL)
        appState.send(.playing)
    }
    
    func stopPlayback() {
        audioPlayerManager.stop()
        appState.send(.readyToPlay)
    }
    
    func reset() {
        stopRecording()
        audioPlayerManager.stop()
        
        recordingURL = nil
        transcriptionResult.send(nil)
        highlightedWordIndex.send(-1)
        appState.send(.idle)
    }
    
    // MARK: - Privates
    private let audioPlayerManager: AudioPlayerManagerType
    private let audioRecorderManager: AudioRecorderManagerType
    private let speechRecognitionManager: SpeechRecognitionManagerType
    
    private let stateSubject: CurrentValueSubject<SpeechRecognitionState, Never> = .init(.idle)
    
    private var recordingURL: URL?
    private let transcriptionResult: CurrentValueSubject<TranscriptionResult?, Never> = .init(nil)
    private let highlightedWordIndex: CurrentValueSubject<Int, Never> = .init(-1)
    private let appState: CurrentValueSubject<AppState, Never> = .init(.idle)
    
    private var cancellables: Set<AnyCancellable> = []
}

extension SpeechRecognitionUseCase {
    
    private func createObservableState() {
        Publishers.CombineLatest3(
            appState,
            transcriptionResult,
            highlightedWordIndex
        )
        .receive(on: DispatchQueue.main)
        .map { state, transResult, highlightedIndex -> SpeechRecognitionState in
            switch state {
            case .idle:
                return .idle
            case .recording:
                return .recording(result: transResult)
            case .readyToPlay:
                guard let transResult else { return .idle }
                return .readyToPlay(result: transResult)
            case .playing:
                guard let transResult else { return .idle }
                return .playing(result: transResult, highlightedWordIndex: highlightedIndex)
            case let .error(description):
                return .error(description)
            }
        }
        .assign(to: \.value, on: stateSubject)
        .store(in: &cancellables)
    }
    
    private func subscribeToAudioPlayerManager() {
        audioPlayerManager.state
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .idle:
                    guard recordingURL != nil else { return }
                    appState.send(.readyToPlay)
                case let .error(error):
                    appState.send(.error(error.localizedDescription))
                case let .playing(playbackTime):
                    updateHighlightedWord(for: playbackTime)
                }
            }
            .store(in: &cancellables)
    }
    
    private func subscribeToAudioRecorderManager() {
        audioRecorderManager.state
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .idle:
                    guard let recordingURL else { return }
                    speechRecognitionManager.transcribeAudioFile(url: recordingURL)
                    appState.send(.readyToPlay)
                case let .error(error):
                    appState.send(.error(error.localizedDescription))
                case let .recording(audioURL):
                    recordingURL = audioURL
                }
            }
            .store(in: &cancellables)
    }
    
    private func subscribeToSpeechRecognitionManager() {
        speechRecognitionManager.state
            .sink { [weak self] result in
                guard let self else { return }
                switch result {
                case .idle:
                    break
                case let .error(error):
                    appState.send(.error(error.localizedDescription))
                case let .transcribing(result):
                    transcriptionResult.send(result)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateHighlightedWord(for currentTime: TimeInterval) {
        guard let result = transcriptionResult.value else {
            highlightedWordIndex.send(-1)
            return
        }
        
        for (index, word) in result.words.enumerated() {
            if currentTime >= word.startTime && currentTime <= word.endTime {
                highlightedWordIndex.send(index)
                return
            }
        }
        
        highlightedWordIndex.send(-1)
    }
}

private extension SpeechRecognitionUseCase {
    enum AppState: Equatable {
        case idle
        case recording
        case readyToPlay
        case playing
        case error(String)
    }
}
