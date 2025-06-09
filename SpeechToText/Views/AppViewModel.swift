import Combine
import Foundation

protocol AppViewModelFactoryType {
    func create() -> AppViewModel
}

struct AppViewModelFactory: AppViewModelFactoryType {
    let speechRecognitionUseCase: SpeechRecognitionUseCaseType
    
    func create() -> AppViewModel {
        .init(speechRecognitionUseCase: speechRecognitionUseCase)
    }
}

final class AppViewModel: ObservableObject {
    
    @Published var viewState: ContentViewState = .recorded
    
    init(speechRecognitionUseCase: SpeechRecognitionUseCaseType) {
        self.speechRecognitionUseCase = speechRecognitionUseCase
        
        speechRecognitionUseCase.state
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .idle:
                    viewState = createIdleViewState()
                case let .error(audioError):
                    print("👺", audioError)
                case let .playing(result, highlightedIndex):
                    viewState = createPlayingViewState(transcriptionResult: result, highlightedWordIndex: highlightedIndex)
                case let .recording(result):
                    viewState = createRecordingViewState(transcriptionResult: result)
                case let .readyToPlay(result):
                    viewState = createReadyToPlayViewState(transcriptionResult: result)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Privates
    private let speechRecognitionUseCase: SpeechRecognitionUseCaseType
    
    private var cancellables: Set<AnyCancellable> = []
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
                        onTap: .init { [speechRecognitionUseCase] in
                            speechRecognitionUseCase.startRecording()
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
                        onTap: .init { [speechRecognitionUseCase] in
                            speechRecognitionUseCase.stopRecording()
                        }
                    )
                )
            )
        )
    }
    
    private func createReadyToPlayViewState(transcriptionResult: TranscriptionResult) -> ContentViewState {
        .init(
            title: "Audio Transcription",
            subtitle: "Ready to play back",
            transcribedViewState: .init(
                placeholder: "",
                highlightedWordIndex: -1,
                words: transcriptionResult.words.map { TranscriptionTextViewState.Word(from: $0) }
            ),
            state: .recorded(
                viewState: .init(
                    playButton: .init(
                        title: "Play",
                        type: .play(playing: false),
                        isEnabled: true,
                        onTap: .init { [speechRecognitionUseCase] in
                            speechRecognitionUseCase.startPlayback()
                        }
                    ),
                    resetButton: .init(
                        title: "Reset",
                        type: .reset,
                        isEnabled: true,
                        onTap: .init { [speechRecognitionUseCase] in
                            speechRecognitionUseCase.reset()
                        }
                    )
                )
            )
        )
    }
    
    private func createPlayingViewState(transcriptionResult: TranscriptionResult,
                                        highlightedWordIndex: Int) -> ContentViewState {
        .init(
            title: "Audio Transcription",
            subtitle: "Playing back your recording",
            transcribedViewState: .init(
                placeholder: "",
                highlightedWordIndex: highlightedWordIndex,
                words: transcriptionResult.words.map { TranscriptionTextViewState.Word(from: $0) }
            ),
            state: .recorded(
                viewState: .init(
                    playButton: .init(
                        title: "Stop Playing",
                        type: .play(playing: true),
                        isEnabled: true,
                        onTap: .init { [speechRecognitionUseCase] in
                            speechRecognitionUseCase.stopPlayback()
                        }
                    ),
                    resetButton: .init(
                        title: "Reset",
                        type: .reset,
                        isEnabled: true,
                        onTap: .init { [speechRecognitionUseCase] in
                            speechRecognitionUseCase.reset()
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
