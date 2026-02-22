import Identifiers
import OrderedCollections

@frozen public struct ResourceInputs {
    @usableFromInline var inputs: OrderedDictionary<Resource, ResourceInput>

    @inlinable init(
        inputs: OrderedDictionary<Resource, ResourceInput>,
    ) {
        self.inputs = inputs
    }
}
extension ResourceInputs {
    @inlinable public static var empty: Self {
        .init(inputs: [:])
    }
}
extension ResourceInputs {
    public var fulfilled: Double {
        self.inputs.values.reduce(1) { min($0, $1.fulfilled) }
    }
}
extension ResourceInputs {
    public mutating func sync(tier: [Quantity<Resource>], scale: (x: Int64, z: Double)) {
        self.inputs.sync(with: tier) {
            $1.turn(unitsDemanded: $0 * scale.x, efficiency: scale.z)
        }
    }

    public mutating func touch(tier: [Quantity<Resource>], scale: (x: Int64, z: Double)) {
        for (i, value): (Int, Quantity<Resource>) in zip(self.inputs.values.indices, tier) {
            self.inputs.values[i].touch(
                value.amount * scale.x,
                efficiency: scale.z,
            )
        }
    }
}
