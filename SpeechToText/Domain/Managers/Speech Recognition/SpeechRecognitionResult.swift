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
        bestTranscription.segments.enumerated().map { index, segment in
            TranscribedWord(
                id: index,
                text: segment.substring,
                startTime: segment.timestamp,
                endTime: segment.timestamp + segment.duration,
                confidence: segment.confidence
            )
        }
    }
}
