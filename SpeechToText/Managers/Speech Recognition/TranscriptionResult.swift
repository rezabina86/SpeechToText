import Foundation

struct TranscribedWord: Equatable {
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let confidence: Float
}

struct TranscriptionResult: Equatable {
    let words: [TranscribedWord]
    let fullText: String
}
