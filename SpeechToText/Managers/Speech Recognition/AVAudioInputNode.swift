import AVFoundation

public protocol AudioInputNodeType {
    func inputFormat(forBus bus: AVAudioNodeBus) -> AVAudioFormat
    func outputFormat(forBus bus: AVAudioNodeBus) -> AVAudioFormat

    func installTap(onBus bus: AVAudioNodeBus, bufferSize: AVAudioFrameCount, format: AVAudioFormat?, block tapBlock: @escaping AVAudioNodeTapBlock)
    func removeTap(onBus bus: AVAudioNodeBus)
}

extension AVAudioInputNode: AudioInputNodeType {}
