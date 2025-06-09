import AVFoundation

protocol AudioEngineType {
    var audioInputNode: AudioInputNodeType { get }
    var isRunning: Bool { get }
    
    func prepare()
    func start() throws
    func stop()
}

extension AVAudioEngine: AudioEngineType {
    var audioInputNode: AudioInputNodeType {
        self.inputNode
    }
}
