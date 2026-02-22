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

    @inlinable public init(
        segmented: [ResourceInput],
        tradeable: [ResourceInput],
        tradeableDaysReserve: Int64
    ) {
        var combined: OrderedDictionary<Resource, ResourceInput> = .init(
            minimumCapacity: segmented.count + tradeable.count
        )
        for input: ResourceInput in segmented {
            combined[input.id] = input
        }
        let inputsPartition: Int = combined.elements.endIndex
        for input: ResourceInput in tradeable {
            combined[input.id] = input
        }
        self.init(
            tradingCooldown: tradeableDaysReserve,
            inputs: combined,
            inputsPartition: inputsPartition
        )
    }
}
extension ResourceInputs {
    @inlinable public static var stockpileDaysFactor: Int64 { 2 }

    @inlinable public var tradeableDaysReserve: Int64 { self.tradingCooldown }
    @inlinable public var count: Int { self.inputs.count }
    @inlinable public var all: [ResourceInput] { self.inputs.values.elements }

    @inlinable public var segmented: ArraySlice<ResourceInput> {
        self.inputs.values.elements[..<self.inputsPartition]
    }
    @inlinable public var tradeable: ArraySlice<ResourceInput> {
        self.inputs.values.elements[self.inputsPartition...]
    }
    @inlinable public var joined: ResourceStockpileCollection<ResourceInput> {
        .init(elements: self.all, elementsPartition: self.inputsPartition)
    }

    public var fulfilled: Double {
        self.inputs.values.reduce(1) { min($0, $1.fulfilled) }
    }
}
extension ResourceInputs {
    @inlinable public subscript(id: Resource) -> ResourceInput? {
        _read   { yield  self.inputs[id] }
        _modify { yield &self.inputs[id] }
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
        from resourceTier: ResourceTier,
        scalingFactor: (x: Int64, z: Double),
        reservingDays: Int64
    ) {
        for (id, amount): (Resource, Int64) in resourceTier.segmented {
            self.inputs[id]!.consume(
                amount * scalingFactor.x,
                efficiency: scalingFactor.z,
                reservedDays: 1
            )
        }
        for (id, amount): (Resource, Int64) in resourceTier.tradeable {
            self.inputs[id]!.consume(
                amount * scalingFactor.x,
                efficiency: scalingFactor.z,
                reservedDays: reservingDays
            )
        }
    }
}
