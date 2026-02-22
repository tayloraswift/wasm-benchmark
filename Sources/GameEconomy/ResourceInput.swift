import Fraction
import Identifiers

@frozen public struct ResourceInput: Identifiable {
    public let id: Resource

    public var unitsDemanded: Int64
    /// Negative if units were returned to the market.
    public var unitsReturned: Int64
    public var units: Reservoir

    /// The “consumed value” is not a real valuation, but merely the fraction of the
    /// unitsAcquired value of the resource that was consumed, rounded up to the nearest unit.
    public var value: Reservoir
    // public var valueAtMarket: Valuation

    /// Most recent available price, can be different from average cost.
    public var price: Double?

    @inlinable public init(
        id: Resource,
        unitsDemanded: Int64,
        unitsReturned: Int64,
        units: Reservoir,
        value: Reservoir,
        price: Double?
    ) {
        self.id = id
        self.unitsDemanded = unitsDemanded
        self.unitsReturned = unitsReturned
        self.units = units
        self.value = value
        self.price = price
    }
}
extension ResourceInput: ResourceStockpile {
    @inlinable public init(id: Resource) {
        self.init(
            id: id,
            unitsDemanded: 0,
            unitsReturned: 0,
            units: .zero,
            value: .zero,
            price: nil
        )
    }
}
extension ResourceInput {
    @inlinable public var unitsConsumed: Int64 {
        self.units.removed + self.unitsReturned
    }

    @inlinable public var valueConsumed: Int64 {
        self.value.removed
    }

    mutating func turn(
        unitsDemanded: Int64,
        efficiency: Double
    ) {
        self.unitsDemanded = .init((Double.init(unitsDemanded) * efficiency).rounded(.up))
        self.unitsReturned = 0
        self.units.turn()
        self.value.turn()
    }
}
extension ResourceInput {
    mutating func consume(_ amount: Int64, efficiency: Double, reservedDays: Int64) {
        let unitsConsumed: Int64 = min(
            Int64.init((Double.init(amount) * efficiency).rounded(.up)),
            reservedDays <= 1 ? self.units.total : self.units.total / reservedDays
        )

        /// the precise (integral) formula is
        /// Δv = floor((Δu %/ u) * v)
        let valueConsumed: Int64 = self.units.total != 0
            ? (unitsConsumed %/ self.units.total) <> self.value.total
            : 0

        self.value -= valueConsumed
        self.units -= unitsConsumed
    }
}
extension ResourceInput {
    var fulfilled: Double {
        let denominator: Int64 = self.unitsDemanded
        return denominator == 0 ? 1 : Double.init(
            self.unitsConsumed + self.units.total
        ) / Double.init(denominator)
    }
}
