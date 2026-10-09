import Foundation

enum FuzzyMatcher {
    static func filter(items: [LaunchItem], query: String, recencyRanks: [String: Int] = [:]) -> [LaunchItem] {
        let lowerQuery = query.lowercased()
        var scored: [(item: LaunchItem, score: Int)] = []

        for item in items {
            let nameScore = score(name: item.name.lowercased(), query: lowerQuery)
            let s = max(nameScore, keywordScore(keywords: item.keywords, query: lowerQuery))
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

    /// Score for a match against an item's search keywords (e.g. "hide my email" → Settings: iCloud).
    /// Must stay below name matches so "Safari" the app beats a settings page that lists "Safari" as a keyword.
    static func keywordScore(keywords: [String], query: String) -> Int {
        guard query.count >= minKeywordQueryLength else { return 0 }
        var best = 0
        for keyword in keywords {
            let lower = keyword.lowercased()
            if lower == query { return exactKeywordScore }
            if lower.hasPrefix(query) || lower.contains(" " + query) { best = prefixKeywordScore }
        }
        return best
    }

    static let minKeywordQueryLength = 3
    // Below the 16 a name prefix match earns, so apps named like the query still win.
    static let exactKeywordScore = 12
    static let prefixKeywordScore = 8

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
