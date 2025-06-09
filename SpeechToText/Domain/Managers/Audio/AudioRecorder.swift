import Foundation
import AVFoundation

protocol AudioRecorderFactoryType {
    func createRecorder(url: URL, settings: [String: Any]) throws -> AudioRecorderType
}

struct AudioRecorderFactory: AudioRecorderFactoryType {
    func createRecorder(url: URL, settings: [String : Any]) throws -> any AudioRecorderType {
        try AVAudioRecorder(url: url, settings: settings)
    }
}

protocol AudioRecorderType: AnyObject {
    var delegate: AVAudioRecorderDelegate? { get set }
    func record() -> Bool
    func stop()
}

extension AVAudioRecorder: AudioRecorderType {}
