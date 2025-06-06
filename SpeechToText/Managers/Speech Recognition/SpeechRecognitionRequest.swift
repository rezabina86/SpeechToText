import Foundation
import AVFoundation
import Speech

protocol SpeechAudioBufferRecognitionRequestType {
    var underlyingRequest: SFSpeechRecognitionRequest { get }
    var shouldReportPartialResults: Bool { get set }
    func append(_ audioPCMBuffer: AVAudioPCMBuffer)
    func endAudio()
}

extension SFSpeechAudioBufferRecognitionRequest: SpeechAudioBufferRecognitionRequestType {
    var underlyingRequest: SFSpeechRecognitionRequest {
        return self
    }
}

protocol SpeechURLRecognitionRequestType: AnyObject {
    var url: URL { get }
    var shouldReportPartialResults: Bool { get set }
    var underlyingRequest: SFSpeechRecognitionRequest { get }
}

extension SFSpeechURLRecognitionRequest: SpeechURLRecognitionRequestType {
    var underlyingRequest: SFSpeechRecognitionRequest {
        self
    }
}

protocol SpeechRecognitionRequestFactoryType {
    func createAudioBufferRequest() -> SpeechAudioBufferRecognitionRequestType
    func createURLRequest(url: URL) -> SpeechURLRecognitionRequestType
}

struct SpeechRecognitionRequestFactory: SpeechRecognitionRequestFactoryType {
    func createAudioBufferRequest() -> SpeechAudioBufferRecognitionRequestType {
        SFSpeechAudioBufferRecognitionRequest()
    }
    
    func createURLRequest(url: URL) -> SpeechURLRecognitionRequestType {
        SFSpeechURLRecognitionRequest(url: url)
    }
}
