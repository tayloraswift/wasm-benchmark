import Identifiers

public protocol ResourceStockpile: Identifiable<Resource> {
    init(id: Resource)
}
