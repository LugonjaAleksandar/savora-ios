import Foundation

/// Codable cache with a timestamp per entry, layered over `KeyValueStore`.
struct MealsCache: Sendable {
    private static let keyPrefix = "meals_cache_"

    private let store: any KeyValueStore
    private let now: @Sendable () -> Date

    init(store: any KeyValueStore, now: @escaping @Sendable () -> Date = Date.init) {
        self.store = store
        self.now = now
    }

    func write<Value: Encodable>(_ value: Value, forKey key: String) {
        store.setValue(Entry(savedAt: now(), value: value), forKey: Self.keyPrefix + key)
    }

    /// Returns the cached value, or `nil` when it is missing, corrupt or older
    /// than `maxAge`. Passing `maxAge: nil` accepts stale data (offline fallback).
    func read<Value: Decodable>(_ type: Value.Type, forKey key: String, maxAge: Duration?) -> Value? {
        let storageKey = Self.keyPrefix + key
        guard let data = store.data(forKey: storageKey) else {
            return nil
        }
        guard let entry = try? JSONDecoder().decode(Entry<Value>.self, from: data) else {
            store.removeValue(forKey: storageKey)
            return nil
        }
        if let maxAge, now().timeIntervalSince(entry.savedAt) > maxAge.timeInterval {
            return nil
        }
        return entry.value
    }
}

private struct Entry<Value> {
    let savedAt: Date
    let value: Value
}

extension Entry: Encodable where Value: Encodable {}

extension Entry: Decodable where Value: Decodable {}

private extension Duration {
    var timeInterval: TimeInterval {
        TimeInterval(components.seconds) + TimeInterval(components.attoseconds) / 1e18
    }
}
