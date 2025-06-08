import SwiftUI

@main
struct SpeechToTextApp: App {
    init(container: ContainerType) {
        self.container = container
        configureDependencies(container)
        self.viewModelFactory = container.resolve()
    }
    
    init() {
        self.init(container: Container())
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModelFactory.create())
        }
    }
    
    // MARK: - Privates
    private let container: ContainerType
    private var configureDependencies = injectDependencies
    private let viewModelFactory: AppViewModelFactoryType
}
