import Identifiers
import OrderedCollections

@frozen public struct ResourceInputs {
    @usableFromInline var tradingCooldown: Int64
    @usableFromInline var inputs: OrderedDictionary<Resource, ResourceInput>
    /// The index of the first **tradeable** resource in ``inputs``, which may be the end
    /// index if there are no tradeable resources.
    @usableFromInline var inputsPartition: Int

    @inlinable init(
        tradingCooldown: Int64,
        inputs: OrderedDictionary<Resource, ResourceInput>,
        inputsPartition: Int
    ) {
        self.tradingCooldown = tradingCooldown
        self.inputs = inputs
        self.inputsPartition = inputsPartition
    }
}
extension ResourceInputs {
    @inlinable public static var empty: Self {
        .init(tradingCooldown: 0, inputs: [:], inputsPartition: 0)
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
        self.inputsPartition = 0
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
