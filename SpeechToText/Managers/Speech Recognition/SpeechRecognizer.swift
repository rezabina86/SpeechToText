import Speech
import Foundation

protocol SpeechRecognizerType {
    var isAvailable: Bool { get }
    func requestAuthorization(_ handler: @escaping (SpeechRecognizerAuthorizationStatus) -> Void)
    func speechRecognitionTask(with request: SFSpeechRecognitionRequest,
                         resultHandler: @escaping (SpeechRecognitionResultType?, Error?) -> Void) -> SpeechRecognitionTaskType
}

extension SFSpeechRecognizer: SpeechRecognizerType {
    func speechRecognitionTask(with request: SFSpeechRecognitionRequest,
                               resultHandler: @escaping (SpeechRecognitionResultType?, Error?) -> Void) -> SpeechRecognitionTaskType {
        self.recognitionTask(with: request, resultHandler: resultHandler)
    }
    
    func requestAuthorization(_ handler: @escaping (SpeechRecognizerAuthorizationStatus) -> Void) {
        type(of: self).requestAuthorization {
            handler($0.toSpeechRecognizerAuthorizationStatus())
        }
    }
}

protocol SpeechRecognizerFactoryType {
    func create() -> SpeechRecognizerType?
}

struct SpeechRecognizerFactory: SpeechRecognizerFactoryType {
    let localeProvider: LocaleProviderType
    
    func create() -> SpeechRecognizerType? {
        SFSpeechRecognizer(locale: localeProvider.locale)
    }
}

enum SpeechRecognizerAuthorizationStatus {
    case notDetermined
    case denied
    case restricted
    case authorized
}

extension SFSpeechRecognizerAuthorizationStatus {
    func toSpeechRecognizerAuthorizationStatus() -> SpeechRecognizerAuthorizationStatus {
        switch self {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .authorized:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }
}
