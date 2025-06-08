import Speech
import Combine
import Foundation

enum SpeechRecognitionManagerResult: Equatable {
    case idle
    case error(SpeechError)
    case transcribing(result: TranscriptionResult)
}

protocol SpeechRecognitionManagerType {
    var state: AnyPublisher<SpeechRecognitionManagerResult, Never> { get }
    
    func requestPermissions() async -> Bool
    func transcribeAudioFile(url: URL)
    func start()
    func stop()
}

final class SpeechRecognitionManager: SpeechRecognitionManagerType {
    
    init(speechRecognizerFactory: SpeechRecognizerFactoryType,
         audioEngine: AudioEngineType,
         requestFactory: SpeechRecognitionRequestFactoryType) {
        self.speechRecognizer = speechRecognizerFactory.create()
        self.audioEngine = audioEngine
        self.requestFactory = requestFactory
    }
    
    var state: AnyPublisher<SpeechRecognitionManagerResult, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    func requestPermissions() async -> Bool {
        await withCheckedContinuation { [speechRecognizer] continuation in
            speechRecognizer?.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    func start() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            stateSubject.send(.error(.recognizerUnavailable))
            return
        }
        
        stopLiveTranscription()
        
        recognitionRequest = requestFactory.createAudioBufferRequest()
        guard recognitionRequest != nil else {
            stateSubject.send(.error(.requestCreationFailed))
            return
        }
        
        recognitionRequest?.shouldReportPartialResults = true
        
        let inputNode = audioEngine.audioInputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self else { return }
            recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            stateSubject.send(.error(.audioEngineError(error.localizedDescription)))
            return
        }
        
        guard let request = recognitionRequest?.underlyingRequest else {
            stateSubject.send(.error(.requestCreationFailed))
            return
        }
        
        recognitionTask = speechRecognizer.speechRecognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            handleRecognitionResult(result: result, error: error)
        }
    }
    
    func stop() {
        stopLiveTranscription()
    }
    
    func transcribeAudioFile(url: URL) {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            stateSubject.send(.error(.recognizerUnavailable))
            return
        }
        let request = requestFactory.createURLRequest(url: url)
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = true
        
        recognitionTask = speechRecognizer.speechRecognitionTask(with: request.underlyingRequest) { [weak self] result, error in
            guard let self else { return }
            if let error = error {
                stateSubject.send(.error(.transcriptionFailed(error.localizedDescription)))
                stopLiveTranscription()
                return
            }
            
            guard let result = result, result.isFinal else { return }
            
            let transcriptionResult = TranscriptionResult(
                words: result.words,
                fullText: result.bestFormattedString
            )
            stateSubject.send(.transcribing(result: transcriptionResult))
        }
    }
    
    // MARK: - Privates
    private let stateSubject: CurrentValueSubject<SpeechRecognitionManagerResult, Never> = .init(.idle)
    
    private let speechRecognizer: SpeechRecognizerType?
    private let audioEngine: AudioEngineType
    private let requestFactory: SpeechRecognitionRequestFactoryType
    
    private var recognitionRequest: SpeechAudioBufferRecognitionRequestType?
    private var recognitionTask: SpeechRecognitionTaskType?
    
    private func stopLiveTranscription() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.audioInputNode.removeTap(onBus: 0)
        }
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        stateSubject.send(.idle)
    }
    
    private func handleRecognitionResult(result: SpeechRecognitionResultType?, error: Error?) {
        if let error = error {
            stateSubject.send(.error(.transcriptionFailed(error.localizedDescription)))
            stopLiveTranscription()
            return
        } else if let result = result {
            let transcriptionResult = TranscriptionResult(
                words: result.words,
                fullText: result.bestFormattedString
            )
            
            stateSubject.send(.transcribing(result: transcriptionResult))
            
            if result.isFinal {
                stopLiveTranscription()
            }
        }
    }
}
