import Foundation

enum SpeechError: Error, LocalizedError, Equatable {
    case recognizerUnavailable
    case requestCreationFailed
    case transcriptionFailed(String)
    case permissionDenied
    case audioEngineError(String)
    
    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "Speech recognizer is not available"
        case .requestCreationFailed:
            return "Failed to create recognition request"
        case .transcriptionFailed(let message):
            return "Transcription failed: \(message)"
        case .permissionDenied:
            return "Speech recognition permission denied"
        case .audioEngineError(let message):
            return "Audio engine error: \(message)"
        }
    }
}
