import AVFoundation

protocol AudioApplicationType {
    static func requestRecordPermission() async -> Bool
}

extension AVAudioApplication: AudioApplicationType {}
