import Foundation

public enum Scope {
    case `default` // Builds a new instance every time
    case container // Holds the instance over the lifetime of the container
    case weakContainer // Holds the instance as long as it is referenced within the containers lifetime. This is only applicable for reference types
}

public protocol ContainerType: AnyObject {
    func register<T>(in scope: Scope, builder: @escaping (ContainerType) -> T)
    func resolve<T>() -> T
}

public extension ContainerType {
    /// Register a new factory closure for type `T` in the `.default` scope.
    ///
    /// - Parameter builder: A factory closure that builds `T`
    func register<T>(builder: @escaping (ContainerType) -> T) {
        register(in: .default, builder: builder)
    }
}

public final class Container: ContainerType {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    /// Register a new factory closure for type `T`.
    ///
    /// - Parameters:
    ///   - scope: Defines the created objects scope (e.g. single instance in this container)
    ///   - builder: A factory closure that builds `T`
    public func register<T>(in scope: Scope, builder: @escaping (ContainerType) -> T) {
        let key = String(reflecting: T.self)

        instances[key] = nil
        weakInstances.removeObject(forKey: key as NSString)

        factories[key] = Factory(scope: scope, build: builder)
    }

    /// Resolves a requested type `T`. A factory closure for `T` needs to be registered before.
    ///
    /// - Returns: `T`
    /// - Throws: `ContainerError`
    public func resolve<T>() -> T {
        let key = String(reflecting: T.self)

        guard let factory = factories[key] else {
            fatalError("no factory found for \(key)")
        }

        switch factory.scope {
        case .default:
            return factory.build(self) as! T
        case .container:
            if let instance = instances[key] as? T {
                return instance
            } else {
                instances[key] = factory.build(self)
                return instances[key] as! T
            }
        case .weakContainer:
            let key = key as NSString
            if let instance = weakInstances.object(forKey: key) as? T {
                return instance
            } else {
                let instance = factory.build(self)
                weakInstances.setObject(instance as AnyObject, forKey: key)
                return instance as! T
            }
        }
    }

    // MARK: Private

    private struct Factory {
        let scope: Scope
        let build: (ContainerType) -> Any
    }

    private var factories: [String: Factory] = [:]
    private var instances: [String: Any] = [:]
    private var weakInstances = NSMapTable<NSString, AnyObject>(
        keyOptions: [.copyIn],
        valueOptions: [.weakMemory]
    )
}
