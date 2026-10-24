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
    static let namePrefixScore = matchScore + wordStartBonus + firstCharBonus
    static let exactKeywordScore = namePrefixScore - 4
    static let prefixKeywordScore = exactKeywordScore - 4

    private static let matchScore = 1
    private static let wordStartBonus = 5
    private static let firstCharBonus = 10

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
                total += matchScore

                if nameIndex == prevMatchIndex + 1 {
                    consecutive += 1
                    total += consecutive * 3
                } else {
                    consecutive = 0
                }

                if nameIndex == 0 || nameChars[nameIndex - 1] == " " || nameChars[nameIndex - 1] == "-" {
                    total += wordStartBonus
                }

                if queryIndex == 0 && nameIndex == 0 {
                    total += firstCharBonus
                }

                prevMatchIndex = nameIndex
                queryIndex += 1
            }
            nameIndex += 1
        }

        guard queryIndex == queryChars.count else { return 0 }

        return total
    }
}
