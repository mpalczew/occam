import Foundation

enum FuzzyMatcher {
    static func filter(items: [LaunchItem], query: String, recencyRanks: [String: Int] = [:]) -> [LaunchItem] {
        let lowerQuery = query.lowercased()
        var scored: [(item: LaunchItem, score: Int)] = []

        for item in items {
            let s = score(name: item.name.lowercased(), query: lowerQuery)
            if s > 0 {
                scored.append((item, s))
            }
        }

        scored.sort(by: { lhs,rhs in 
            if (lhs.score > rhs.score) { return true }
            else if (lhs.score < rhs.score) { return false }
            else {
                let lhsRecencyRank = recencyRanks[lhs.item.url.absoluteString] ?? Int.max
                let rhsRecencyRank = recencyRanks[rhs.item.url.absoluteString] ?? Int.max
                return lhsRecencyRank < rhsRecencyRank
            }
        })

        return scored.map(\.item)
    }

    static func score(name: String, query: String) -> Int {
        let nameChars = Array(name)
        let queryChars = Array(query)

        guard !queryChars.isEmpty else { return 1 }

        var total = 0
        var nameIndex = 0
        var queryIndex = 0
        var prevMatchIndex = -2
        var consecutive = 0

        while queryIndex < queryChars.count && nameIndex < nameChars.count {
            if nameChars[nameIndex] == queryChars[queryIndex] {
                total += 1

                // Consecutive character bonus
                if nameIndex == prevMatchIndex + 1 {
                    consecutive += 1
                    total += consecutive * 3
                } else {
                    consecutive = 0
                }

                // Start-of-word bonus
                if nameIndex == 0 || nameChars[nameIndex - 1] == " " || nameChars[nameIndex - 1] == "-" {
                    total += 5
                }

                // Prefix bonus
                if queryIndex == 0 && nameIndex == 0 {
                    total += 10
                }

                prevMatchIndex = nameIndex
                queryIndex += 1
            }
            nameIndex += 1
        }

        // All query characters must match
        guard queryIndex == queryChars.count else { return 0 }

        return total
    }
}
