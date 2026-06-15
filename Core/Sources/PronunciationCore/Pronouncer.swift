/// One word's pronunciation, ready for the UI: audio is produced separately from `ipa`/`word`.
public struct Pronunciation: Equatable, Sendable, Identifiable {
    public var id: String { word }
    public let word: String          // original (display) form
    public let ipa: String           // broad IPA with stress, e.g. "muˈse.o"
    public let syllables: [String]   // orthographic, e.g. ["mu", "se", "o"]
    public let stressIndex: Int      // index into `syllables`
    public let tips: [String]        // Dutch coaching, ≤ 3 lines
}

/// Public, offline API: a Spanish word -> its pronunciation + Dutch coaching.
public enum Pronouncer {
    public static func pronounce(_ word: String) -> Pronunciation {
        let trimmed = trim(word)
        let result = SpanishPhonology.analyze(trimmed)
        let stressedSyllable = result.syllables.indices.contains(result.stressIndex)
            ? result.syllables[result.stressIndex]
            : trimmed
        let tips = DutchCoaching.tips(for: trimmed, stressedSyllable: stressedSyllable)
        return Pronunciation(
            word: trimmed,
            ipa: result.ipa,
            syllables: result.syllables,
            stressIndex: result.stressIndex,
            tips: tips
        )
    }

    private static func trim(_ s: String) -> String {
        let ws: Set<Character> = [" ", "\t", "\n", "\r"]
        var chars = Array(s)
        while let f = chars.first, ws.contains(f) { chars.removeFirst() }
        while let l = chars.last, ws.contains(l) { chars.removeLast() }
        return String(chars)
    }
}
