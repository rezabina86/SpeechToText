import Speech

protocol SpeechRecognitionTaskType {
    func cancel()
    func finish()
}

extension SFSpeechRecognitionTask: SpeechRecognitionTaskType {}
