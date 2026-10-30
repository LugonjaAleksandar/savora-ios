import Foundation
import Synchronization

/// Minimal persistence contract. Repositories depend on this instead of
/// `UserDefaults`, so tests run against `InMemoryKeyValueStore`.
protocol KeyValueStore: Sendable {
    func data(forKey key: String) -> Data?
    func set(_ data: Data?, forKey key: String)
}

extension KeyValueStore {
    func value<Value: Decodable>(_ type: Value.Type, forKey key: String) -> Value? {
        guard let data = data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(type, from: data)
    }

    func setValue<Value: Encodable>(_ value: Value, forKey key: String) {
        set(try? JSONEncoder().encode(value), forKey: key)
    }

    func removeValue(forKey key: String) {
        set(nil, forKey: key)
    }
}

/// `UserDefaults` is documented as thread-safe, hence `@unchecked Sendable`.
final class UserDefaultsStore: KeyValueStore, @unchecked Sendable {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func data(forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }

    func set(_ data: Data?, forKey key: String) {
        defaults.set(data, forKey: key)
    }
}

final class InMemoryKeyValueStore: KeyValueStore {
    private let storage = Mutex<[String: Data]>([:])

    func data(forKey key: String) -> Data? {
        storage.withLock { $0[key] }
    }

    func set(_ data: Data?, forKey key: String) {
        storage.withLock { $0[key] = data }
    }
}
