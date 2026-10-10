import Foundation

struct CacheEntry<Value> {
    let savedAt: Date
    let value: Value
}

extension CacheEntry: Encodable where Value: Encodable {}

extension CacheEntry: Decodable where Value: Decodable {}
