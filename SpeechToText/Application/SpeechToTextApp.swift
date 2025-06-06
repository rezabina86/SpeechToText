import SwiftUI

@main
struct SpeechToTextApp: App {
    init(container: ContainerType) {
        self.container = container
        configureDependencies(container)
    }
    
    init() {
        self.init(container: Container())
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    // MARK: - Privates
    private let container: ContainerType
    private var configureDependencies = injectDependencies
}
