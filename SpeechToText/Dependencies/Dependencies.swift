import Foundation
import AVFoundation

public func injectDependencies(into container: ContainerType) {
    
    container.register { _ -> AudioPlayerFactoryFactoryType in
        AudioPlayerFactoryFactory()
    }
    
    container.register { _ -> AudioRecorderFactoryType in
        AudioRecorderFactory()
    }
    
    container.register { _ -> AudioSessionType in
        AVAudioSession()
    }
    
    container.register { container -> AudioPlayerManagerType in
        AudioPlayerManager(audioPlayerFactoryFactory: container.resolve(),
                           timerFactory: container.resolve())
    }
    
    container.register { container -> AudioRecorderManagerType in
        AudioRecorderManager(audioSession: container.resolve(),
                              audioRecorderFactory: container.resolve(),
                              fileManager: container.resolve(),
                              dateProvider: container.resolve(),
                              audioApplication: container.resolve())
    }
    
    container.register { _ -> AudioEngineType in
        AVAudioEngine()
    }
    
    container.register { container -> SpeechRecognitionManagerType in
        SpeechRecognitionManager(speechRecognizerFactory: container.resolve(),
                                 audioEngine: container.resolve(),
                                 requestFactory: container.resolve())
    }
    
    container.register { _ -> SpeechRecognitionRequestFactoryType in
        SpeechRecognitionRequestFactory()
    }
    
    container.register { _ -> SpeechRecognizerFactoryType in
        SpeechRecognizerFactory(localeProvider: container.resolve())
    }
    
    container.register { _ -> DateProviderType in
        DateProvider()
    }
    
    container.register { _ -> FileManagerType in
        FileManager.default
    }
    
    container.register { _ -> LocaleProviderType in
        LocaleProvider()
    }
    
    container.register { _ -> TimerFactoryType in
        TimerFactory()
    }
    
    container.register { _ -> AudioApplicationType.Type in
        AVAudioApplication.self
    }
    
    container.register { container -> AppViewModelFactoryType in
        AppViewModelFactory(speechRecognitionUseCase: container.resolve())
    }
    
    container.register { container -> SpeechRecognitionUseCaseType in
        SpeechRecognitionUseCase(audioPlayerManager: container.resolve(),
                                 audioRecorderManager: container.resolve(),
                                 speechRecognitionManager: container.resolve())
    }
}
