extension Collection<Int64> {
    /// Distributes funds proportionately among shareholders based on their shares.
    ///
    /// This version uses precise integer arithmetic, so if it returns a result, then it sums to
    /// the exact amount of `funds` provided.
    ///
    /// -   Parameters:
    ///     -   funds: The total amount of funds to distribute.
    ///
    /// -   Returns:
    ///     An array where each element represents the amount of funds allocated to the
    ///     corresponding shareholder.
    @inlinable public func distribute(_ funds: Int64) -> [Int64]? {
        // can’t use `\.self`, the compiler forgets to optimize it
        self.distribute(funds) { $0 }
    }
    /// Reduce each element in the collection proportionately such that the sum of the values
    /// in the returned array is at most `limit`, unless the collection sums to zero, in which
    /// case `nil` is returned.
    @inlinable public func split(limit: Int64) -> [Int64]? {
        // can’t use `\.self`, the compiler forgets to optimize it
        self.split(limit: limit) { $0 }
    }
}
extension Collection<Double> {
    /// Distributes funds proportionately among shareholders based on their shares.
    ///
    /// This version is inexact, and may return a result that sums to less than the amount
    /// of `funds` provided! However, it will never sum to a value greater than `funds`.
    @inlinable public func distribute(_ funds: Int64) -> [Int64]? {
        self.distribute(funds) { $0 }
    }
    @inlinable public func split(limit: Int64) -> [Int64]? {
        self.split(limit: limit) { $0 }
    }
}
extension Collection {
    /// Distributes funds proportionately among shareholders based on their shares, computed by
    /// the provided closure.
    ///
    /// This version uses precise integer arithmetic, so if it returns a result, then it sums to
    /// the exact amount of `funds` provided.
    @inlinable public func distribute(_ funds: Int64, share: (Element) -> Int64) -> [Int64]? {
        self.distribute(share: share) { _ in funds }
    }
    /// Distributes funds proportionately among shareholders based on their shares, computed by
    /// the provided closure.
    ///
    /// This version is inexact, and may return a result that sums to less than the amount
    /// of `funds` provided! However, it will never sum to a value greater than `funds`.
    @inlinable public func distribute(_ funds: Int64, share: (Element) -> Double) -> [Int64]? {
        self.distribute(share: share) { _ in funds }
    }
}
extension Collection {
    /// Reduce the value returned by calling the provided closure on each element in the
    /// collection such that the sum of the values in the returned array is at most `limit`,
    /// unless the mapped values of the collection sum to zero, in which case `nil` is returned.
    @inlinable public func split(limit: Int64, share: (Element) -> Int64) -> [Int64]? {
        // TODO: optimization opportunity here where the sum of shares is under the limit?
        self.distribute(share: share) { Swift.min($0, limit) }
    }
    @inlinable public func split(limit: Int64, share: (Element) -> Double) -> [Int64]? {
        // TODO: optimization opportunity here where the sum of shares is under the limit?
        self.distribute(share: share) {
            if  let shares: Int64 = .init(exactly: $0.rounded(.up)) {
                return Swift.min(shares, limit)
            } else {
                return limit
            }
        }
    }
}
extension Collection {
    /// Distributes funds proportionately among shareholders based on their holdings.
    ///
    /// This version uses precise integer arithmetic, so if it returns a result, then it sums to
    /// the exact amount of `funds` provided.
    ///
    /// -   Parameters:
    ///     -   share:
    ///         A closure that receives an element of the collection and returns the number of
    ///         shares held by that element.
    ///     -   funds:
    ///         A closure that receives the total shares in the collection and returns the total
    ///         amount of funds to distribute.
    ///
    /// -   Returns:
    ///     An array where each element represents the amount of funds allocated to the
    ///     corresponding shareholder.
    @inlinable public func distribute(
        share: (Element) -> Int64,
        funds: (Int64) -> Int64,
    ) -> [Int64]? {
        let shares: Int64 = self.reduce(0) { $0 + share($1) }
        if  shares <= 0 {
            // If no one has shares, no one gets funds
            return nil
        }

        return self.distribute(exactly: funds(shares), shares: shares, share: share)
    }

    /// Distributes funds proportionately among shareholders based on their holdings,
    /// using floating-point weights.
    ///
    /// This version is inexact, and may return a result that sums to less than the amount
    /// of `funds` provided! However, it will never sum to a value greater than `funds`.
    @inlinable func distribute(
        share: (Element) -> Double,
        funds: (Double) -> Int64,
    ) -> [Int64]? {
        let shares: Double = self.reduce(0) { $0 + share($1) }
        if shares <= 0 {
            return nil
        }

        return self.distribute(upTo: funds(shares), shares: shares, share: share)
    }
}
extension Collection {
    @inlinable func distribute(
        exactly funds: Int64,
        shares: Int64,
        share: (Element) -> Int64
    ) -> [Int64] {
        // Initialize allocation array
        var allocations: [Int64] = .init(repeating: 0, count: self.count)
        var allocated: Int64 = 0

        // First pass: calculate the floor of proportional distribution
        for (i, element): (Int, Element) in zip(allocations.indices, self) {
            let numerator: (Int64, UInt64) = funds.multipliedFullWidth(by: share(element))
            let (amount, _): (Int64, Int64) = shares.dividingFullWidth(numerator)
            allocations[i] = amount
            allocated += amount
        }

        // Second pass: distribute remaining funds to earlier shareholders
        // who have a non-zero share
        for (i, element): (Int, Element) in zip(allocations.indices, self) {
            guard allocated < funds else {
                break
            }

            guard share(element) > 0 else {
                continue
            }

            allocations[i] += 1
            allocated += 1
        }

        return allocations
    }

    @inlinable func distribute(
        upTo funds: Int64,
        shares: Double,
        share: (Element) -> Double
    ) -> [Int64] {
        var allocations: [Int64] = .init(repeating: 0, count: self.count)
        var remaining: Int64 = funds
        let dividend: Double = .init(funds)

        for (i, element): (Int, Element) in zip(allocations.indices, self) {
            let amount: Double = dividend * share(element) / shares
            guard
            let amount: Int64 = .init(exactly: amount.rounded(.down)) else {
                // If we can’t represent this exactly, it’s definitely too large
                allocations[i] = remaining
                remaining = 0
                return allocations
            }
            if  amount > remaining {
                allocations[i] = remaining
                remaining = 0
                return allocations
            } else if remaining > 0 {
                allocations[i] = amount
                remaining -= amount
            } else {
                return allocations
            }
        }

        for (i, element): (Int, Element) in zip(allocations.indices, self) {
            guard remaining > 0 else {
                break
            }
            guard share(element) > 0 else {
                continue
            }
            allocations[i] += 1
            remaining -= 1
        }

        return allocations
    }
}
