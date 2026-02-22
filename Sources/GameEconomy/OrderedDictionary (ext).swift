import Identifiers
import OrderedCollections


@frozen public struct ResourceDictionary<Value> where Value: ResourceStockpile {
    @usableFromInline var indices: [Resource: Int]
    @usableFromInline var ordered: [Value]

    @inlinable init() {
        self.indices = [:]
        self.ordered = []
    }
}
extension ResourceDictionary {
    @inlinable init(minimumCapacity: Int) {
        self.init()
        self.indices.reserveCapacity(minimumCapacity)
        self.ordered.reserveCapacity(minimumCapacity)
    }
}

extension ResourceDictionary: Sendable where Value: Sendable {}
extension ResourceDictionary: Equatable where Value: Equatable {}
extension ResourceDictionary {
    @inlinable subscript(_ resource: Resource) -> Value? {
        get {
            guard let i: Int = self.indices[resource] else { return nil }
            return self.ordered[i]
        }
        set(value) {
            if let value: Value = value {
                if let i: Int = self.indices[resource] {
                    self.ordered[i] = value
                } else {
                    self.indices[resource] = self.ordered.count
                    self.ordered.append(value)
                }
            } else if let i: Int = self.indices.removeValue(forKey: resource) {
                self.ordered.remove(at: i)
                for j: Int in i..<self.ordered.count {
                    self.indices[self.ordered[j].id] = j
                }
            }
        }
    }
    /// Synchronizes the entries in this dictionary with keys derived from the given array of
    /// coefficients. After this function returns, the dictionary is guaranteed to contain
    /// the same keys as the coefficients, and in the same order.
    mutating func sync(
        with coefficients: [Quantity<Resource>],
        sync: (Int64, inout Value) -> Void
    ) {
        // Fast path: in-place update
        inplace: do {
            guard self.ordered.count == coefficients.count else {
                break inplace
            }
            for (i, c): (Value, Quantity<Resource>) in zip(self.ordered, coefficients)
                where i.id != c.unit {
                break inplace
            }

            for (i, c): (Int, Quantity<Resource>) in zip(self.ordered.indices, coefficients) {
                sync(c.amount, &self.ordered[i])
            }

            return
        }

        // Slow path: the arrays are not the same length, or the resources do not match.
        var reallocated: Self = .init(minimumCapacity: coefficients.count)

        for c: Quantity<Resource> in coefficients {
            var value: Value = self[c.unit] ?? .init(id: c.unit)
            sync(c.amount, &value)

            guard case nil = reallocated.indices.updateValue(
                reallocated.ordered.endIndex,
                forKey: c.unit
            ) else {
                fatalError("Duplicate resource in coefficients: \(c.unit)")
            }
            reallocated.ordered.append(value)
        }

        self = reallocated
    }
}

extension OrderedDictionary where Key == Resource, Value: ResourceStockpile {
    /// Synchronizes the entries in this dictionary with keys derived from the given array of
    /// coefficients. After this function returns, the dictionary is guaranteed to contain
    /// the same keys as the coefficients, and in the same order.
    mutating func sync(
        with coefficients: [Quantity<Resource>],
        sync: (Int64, inout Value) -> Void
    ) {
        // Fast path: in-place update
        inplace: do {
            guard self.count == coefficients.count else {
                break inplace
            }
            for (i, c): (Value, Quantity<Resource>) in zip(self.values, coefficients)
                where i.id != c.unit {
                break inplace
            }

            for (i, c): (Int, Quantity<Resource>) in zip(self.values.indices, coefficients) {
                sync(c.amount, &self.values[i])
            }

            return
        }

        // Slow path: the arrays are not the same length, or the resources do not match.
        var reallocated: Self = .init(minimumCapacity: coefficients.count)

        for c: Quantity<Resource> in coefficients {
            var value: Value = self[c.unit] ?? .init(id: c.unit)
            sync(c.amount, &value)
            reallocated[c.unit] = value
        }

        self = reallocated
    }
}
