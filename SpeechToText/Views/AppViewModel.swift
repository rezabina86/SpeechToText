import Combine
import Foundation

protocol AppViewModelFactoryType {
    func create() -> AppViewModel
}

struct AppViewModelFactory: AppViewModelFactoryType {
    let audioPlayerManager: AudioPlayerManagerType
    let audioRecorderManager: AudioRecorderManagerType
    let speechRecognitionManager: SpeechRecognitionManagerType
    
    func create() -> AppViewModel {
        .init(audioPlayerManager: audioPlayerManager,
              audioRecorderManager: audioRecorderManager,
              speechRecognitionManager: speechRecognitionManager)
    }
}

final class AppViewModel: ObservableObject {
    
    @Published var viewState: ContentViewState = .recorded
    
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
        
        createAndUpdateViewState()
    }
    
    // MARK: - Privates
    private let audioPlayerManager: AudioPlayerManagerType
    private let audioRecorderManager: AudioRecorderManagerType
    private let speechRecognitionManager: SpeechRecognitionManagerType
    
    private var recordingURL: URL?
    
    private var appState: CurrentValueSubject<AppState, Never> = .init(.idle)
    private let transcriptionResult: CurrentValueSubject<TranscriptionResult?, Never> = .init(nil)
    private let highlightedWordIndex: CurrentValueSubject<Int, Never> = .init(-1)
    
    private var cancellables: Set<AnyCancellable> = []
    
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

// MARK: - Subcriptions
extension AppViewModel {
    private func createAndUpdateViewState() {
        Publishers.CombineLatest3(
            appState,
            transcriptionResult,
            highlightedWordIndex
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] state, transResult, highlightedIndex in
            guard let self else { return }
            switch state {
            case .idle:
                viewState = createIdleViewState()
            case .recording:
                viewState = createRecordingViewState(transcriptionResult: transResult)
            case .readyToPlay:
                viewState = createReadyToPlayViewState(transcriptionResult: transResult)
            case .playing:
                viewState = createPlayingViewState(transcriptionResult: transResult, highlightedWordIndex: highlightedIndex)
            case .error:
                break
            }
        }
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
                    print(error)
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
                    print(error)
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
                    print(error)
                case let .transcribing(result):
                    transcriptionResult.send(result)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Controllers
extension AppViewModel {
    private func startRecording() {
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
    
    private func stopRecording() {
        speechRecognitionManager.stop()
        audioRecorderManager.stop()
    }
    
    private func startPlayback() {
        guard let recordingURL else {
            return
        }
        
        audioPlayerManager.play(audioURL: recordingURL)
        appState.send(.playing)
    }
    
    private func stopPlayback() {
        audioPlayerManager.stop()
        appState.send(.readyToPlay)
    }
    
    private func reset() {
        stopRecording()
        audioPlayerManager.stop()
        
        recordingURL = nil
        transcriptionResult.send(nil)
        highlightedWordIndex.send(-1)
        appState.send(.idle)
    }
}

// MARK: - View State converters
extension AppViewModel {
    private func createIdleViewState() -> ContentViewState {
        .init(
            title: "Audio Transcription",
            subtitle: "Ready to record",
            transcribedViewState: .init(
                placeholder: "Your transcription will appear here...",
                highlightedWordIndex: -1,
                words: []
            ),
            state: .idle(
                viewState: .init(
                    recordButton: .init(
                        title: "Record",
                        type: .record(recording: false),
                        isEnabled: true,
                        onTap: .init { [weak self] in
                            guard let self else { return }
                            startRecording()
                        }
                    )
                )
            )
        )
    }
    
    private func createRecordingViewState(transcriptionResult: TranscriptionResult?) -> ContentViewState {
        .init(
            title: "Audio Transcription",
            subtitle: "Recording... Speak now",
            transcribedViewState: .init(
                placeholder: "Your transcription will appear here...",
                highlightedWordIndex: -1,
                words: transcriptionResult?.words.map { TranscriptionTextViewState.Word(from: $0) } ?? []
            ),
            state: .recording(
                viewState: .init(
                    recordButton: .init(
                        title: "Stop Recording",
                        type: .record(recording: true),
                        isEnabled: true,
                        onTap: .init { [weak self] in
                            guard let self else { return }
                            stopRecording()
                        }
                    )
                )
            )
        )
    }
    
    private func createReadyToPlayViewState(transcriptionResult: TranscriptionResult?) -> ContentViewState {
        .init(
            title: "Audio Transcription",
            subtitle: "Ready to play back",
            transcribedViewState: .init(
                placeholder: "",
                highlightedWordIndex: -1,
                words: transcriptionResult?.words.map { TranscriptionTextViewState.Word(from: $0) } ?? []
            ),
            state: .recorded(
                viewState: .init(
                    playButton: .init(
                        title: "Play",
                        type: .play(playing: false),
                        isEnabled: true,
                        onTap: .init { [weak self] in
                            guard let self else { return }
                            startPlayback()
                        }
                    ),
                    resetButton: .init(
                        title: "Reset",
                        type: .reset,
                        isEnabled: true,
                        onTap: .init { [weak self] in
                            guard let self else { return }
                            reset()
                        }
                    )
                )
            )
        )
    }
    
    private func createPlayingViewState(transcriptionResult: TranscriptionResult?,
                                        highlightedWordIndex: Int) -> ContentViewState {
        .init(
            title: "Audio Transcription",
            subtitle: "Playing back your recording",
            transcribedViewState: .init(
                placeholder: "",
                highlightedWordIndex: highlightedWordIndex,
                words: transcriptionResult?.words.map { TranscriptionTextViewState.Word(from: $0) } ?? []
            ),
            state: .recorded(
                viewState: .init(
                    playButton: .init(
                        title: "Stop Playing",
                        type: .play(playing: true),
                        isEnabled: true,
                        onTap: .init { [weak self] in
                            guard let self else { return }
                            stopPlayback()
                        }
                    ),
                    resetButton: .init(
                        title: "Reset",
                        type: .reset,
                        isEnabled: true,
                        onTap: .init { [weak self] in
                            guard let self else { return }
                            reset()
                        }
                    )
                )
            )
        )
    }
}

private extension TranscriptionTextViewState.Word {
    init(from model: TranscribedWord) {
        self = .init(index: model.id,
                     text: model.text)
    }
}
