import Speech

protocol SpeechRecognitionResultType {
    var isFinal: Bool { get }
    var bestFormattedString: String { get }
    var formattedTranscriptions: [String] { get }
    var words: [TranscribedWord] { get }
}

extension SFSpeechRecognitionResult: SpeechRecognitionResultType {
    public var bestFormattedString: String {
        bestTranscription.formattedString
    }

    public var formattedTranscriptions: [String] {
        transcriptions.map(\.formattedString)
    }
    
    var words: [TranscribedWord] {
        bestTranscription.segments.map { segment in
            TranscribedWord(
                text: segment.substring,
                startTime: segment.timestamp,
                endTime: segment.timestamp + segment.duration,
                confidence: segment.confidence
            )
        }
    }
}
