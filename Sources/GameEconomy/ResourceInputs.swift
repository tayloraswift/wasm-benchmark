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
    public mutating func sync(
        with tier: [Quantity<Resource>],
        scalingFactor: (x: Int64, z: Double),
    ) {
        self.inputs.sync(with: tier) {
            $1.turn(unitsDemanded: $0 * scalingFactor.x, efficiency: scalingFactor.z)
        }
    }

    public mutating func consume(
        from resourceTier: [Quantity<Resource>],
        scalingFactor: (x: Int64, z: Double),
    ) {
        for (i, value): (Int, Quantity<Resource>) in zip(self.inputs.values.indices, resourceTier) {
            self.inputs.values[i].consume(
                value.amount * scalingFactor.x,
                efficiency: scalingFactor.z,
                reservedDays: 1
            )
        }
    }
}
