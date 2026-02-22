import Identifiers

@frozen public struct ResourceInput: Identifiable {
    public let id: Resource

    public var unitsDemanded: Int64
    public var unitsReturned: Int64
    public var price: Double?

    @inlinable public init(
        id: Resource,
        unitsDemanded: Int64,
        unitsReturned: Int64,
        price: Double?
    ) {
        self.id = id
        self.unitsDemanded = unitsDemanded
        self.unitsReturned = unitsReturned
        self.price = price
    }
}
extension ResourceInput {
    @inlinable public init(id: Resource) {
        self.init(
            id: id,
            unitsDemanded: 0,
            unitsReturned: 0,
            price: nil
        )
    }
}
extension ResourceInput {
    mutating func turn(
        unitsDemanded: Int64,
        efficiency: Double
    ) {
        self.unitsDemanded = .init((Double.init(unitsDemanded) * efficiency).rounded(.up))
        self.unitsReturned = 0
    }
}
extension ResourceInput {
    mutating func touch(_ amount: Int64, efficiency: Double) {
        self.unitsReturned = self.unitsDemanded - Int64.init(
            (Double.init(amount) * efficiency).rounded(.up)
        )
    }
}
extension ResourceInput {
    var fulfilled: Double { 1 }
}
