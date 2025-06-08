import SwiftUI

struct ContentView: View {
    
    var body: some View {
        makeBody(for: viewModel.viewState)
    }
    
    // MARK: - Privates
    @StateObject var viewModel: AppViewModel
    
    @ViewBuilder
    private func makeBody(for viewState: ContentViewState) -> some View {
        VStack(spacing: 18) {
            VStack {
                Text(viewState.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(viewState.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            TranscriptionTextView(viewState: viewState.transcribedViewState)
                .frame(minHeight: 200)
            
            switch viewState.state {
            case let .idle(viewState):
                createIdleView(from: viewState)
            case let .playing(viewState):
                createPlayingView(from: viewState)
            case let .recording(viewState):
                createRecordingView(from: viewState)
            case let .recorded(viewState):
                createRecordedView(from: viewState)
            }
        }
        .padding()
        .animation(.easeInOut(duration: 0.15), value: viewModel.viewState)
    }
    
    @ViewBuilder
    private func createIdleView(from viewState: ContentViewState.IdleViewState) -> some View {
        ActionButton(
            state: .init(
                title: viewState.recordButton.title,
                systemImage: buttonImageName(for: viewState.recordButton.type),
                color: buttonColor(for: viewState.recordButton.type),
                isEnabled: viewState.recordButton.isEnabled,
                onTap: viewState.recordButton.onTap
            )
        )
    }
    
    @ViewBuilder
    private func createRecordingView(from viewState: ContentViewState.RecordingViewState) -> some View {
        ActionButton(
            state: .init(
                title: viewState.recordButton.title,
                systemImage: buttonImageName(for: viewState.recordButton.type),
                color: buttonColor(for: viewState.recordButton.type),
                isEnabled: viewState.recordButton.isEnabled,
                onTap: viewState.recordButton.onTap
            )
        )
    }
    
    @ViewBuilder
    private func createRecordedView(from viewState: ContentViewState.RecordedViewState) -> some View {
        HStack(spacing: 18) {
            ActionButton(
                state: .init(
                    title: viewState.playButton.title,
                    systemImage: buttonImageName(for: viewState.playButton.type),
                    color: buttonColor(for: viewState.playButton.type),
                    isEnabled: viewState.playButton.isEnabled,
                    onTap: viewState.playButton.onTap
                )
            )
            ActionButton(
                state: .init(
                    title: viewState.resetButton.title,
                    systemImage: buttonImageName(for: viewState.resetButton.type),
                    color: buttonColor(for: viewState.resetButton.type),
                    isEnabled: viewState.resetButton.isEnabled,
                    onTap: viewState.resetButton.onTap
                )
            )
        }
    }
    
    @ViewBuilder
    private func createPlayingView(from viewState: ContentViewState.PlayingViewState) -> some View {
        HStack(spacing: 18) {
            ActionButton(
                state: .init(
                    title: viewState.playButton.title,
                    systemImage: buttonImageName(for: viewState.playButton.type),
                    color: buttonColor(for: viewState.playButton.type),
                    isEnabled: viewState.playButton.isEnabled,
                    onTap: viewState.playButton.onTap
                )
            )
            ActionButton(
                state: .init(
                    title: viewState.resetButton.title,
                    systemImage: buttonImageName(for: viewState.resetButton.type),
                    color: buttonColor(for: viewState.resetButton.type),
                    isEnabled: viewState.resetButton.isEnabled,
                    onTap: viewState.resetButton.onTap
                )
            )
        }
    }
    
    private func buttonColor(for type: ContentViewState.ButtonViewState.ButtonType) -> Color {
        switch type {
        case let .play(playing):
                playing ? .red :.green
        case let .record(recording):
            recording ? .red : .blue
        case .reset:
                .orange
        }
    }
    
    private func buttonImageName(for type: ContentViewState.ButtonViewState.ButtonType) -> String {
        switch type {
        case let .play(playing):
            playing ? "stop.circle.fill" : "play.circle.fill"
        case let .record(recording):
            recording ? "stop.circle.fill" : "mic.circle.fill"
        case .reset:
            "arrow.clockwise"
        }
    }
}

struct ContentViewState: Equatable {
    let title: String
    let subtitle: String
    let transcribedViewState: TranscriptionTextViewState
    let state: State
    
    enum State: Equatable {
        case idle(viewState: IdleViewState)
        case playing(viewState: PlayingViewState)
        case recording(viewState: RecordingViewState)
        case recorded(viewState: RecordedViewState)
    }
}

extension ContentViewState {
    struct IdleViewState: Equatable {
        let recordButton: ButtonViewState
    }
    
    struct PlayingViewState: Equatable {
        let playButton: ButtonViewState
        let resetButton: ButtonViewState
    }
    
    struct RecordingViewState: Equatable {
        let recordButton: ButtonViewState
    }
    
    struct RecordedViewState: Equatable {
        let playButton: ButtonViewState
        let resetButton: ButtonViewState
    }
    
    struct ButtonViewState: Equatable {
        let title: String
        let type: ButtonType
        let isEnabled: Bool
        let onTap: UserAction
        
        enum ButtonType: Equatable {
            case play(playing: Bool)
            case record(recording: Bool)
            case reset
        }
    }
}

extension ContentViewState {
    static let idle: Self = .init(
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
                    onTap: .fake
                )
            )
        )
    )
    
    static let recording: Self = .init(
        title: "Audio Transcription",
        subtitle: "Recording... Speak now",
        transcribedViewState: .init(
            placeholder: "",
            highlightedWordIndex: -1,
            words: [
                .init(index: 0, text: "Hello"),
                .init(index: 1, text: "World")
            ]
        ),
        state: .recording(
            viewState: .init(
                recordButton: .init(
                    title: "Stop Recording",
                    type: .record(recording: true),
                    isEnabled: true,
                    onTap: .fake
                )
            )
        )
    )
    
    static let recorded: Self = .init(
        title: "Audio Transcription",
        subtitle: "Ready to play back",
        transcribedViewState: .init(
            placeholder: "",
            highlightedWordIndex: -1,
            words: [
                .init(index: 0, text: "Hello"),
                .init(index: 1, text: "World")
            ]
        ),
        state: .recorded(
            viewState: .init(
                playButton: .init(
                    title: "Play",
                    type: .play(playing: false),
                    isEnabled: true,
                    onTap: .fake
                ),
                resetButton: .init(
                    title: "Reset",
                    type: .reset,
                    isEnabled: true,
                    onTap: .fake
                )
            )
        )
    )
    
    static let playing: Self = .init(
        title: "Audio Transcription",
        subtitle: "Playing back your recording",
        transcribedViewState: .init(
            placeholder: "",
            highlightedWordIndex: 1,
            words: [
                .init(index: 0, text: "Hello"),
                .init(index: 1, text: "World")
            ]
        ),
        state: .recorded(
            viewState: .init(
                playButton: .init(
                    title: "Stop Playing",
                    type: .play(playing: true),
                    isEnabled: true,
                    onTap: .fake
                ),
                resetButton: .init(
                    title: "Reset",
                    type: .reset,
                    isEnabled: true,
                    onTap: .fake
                )
            )
        )
    )
}
