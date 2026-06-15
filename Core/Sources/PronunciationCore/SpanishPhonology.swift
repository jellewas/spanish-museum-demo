/// Rule-based grapheme-to-phoneme for neutral ("regular") Latin-American Spanish.
/// Conventions: seseo (z, ce, ci -> /s/), yeismo (ll -> /ʝ/). Broad IPA suitable
/// for a pronunciation-teaching demo, not narrow phonetic detail.
enum SpanishPhonology {

    struct Result {
        let ipa: String          // e.g. "muˈse.o"
        let syllables: [String]  // orthographic, e.g. ["mu", "se", "o"]
        let stressIndex: Int     // index into `syllables`
    }

    // MARK: - Unit model

    private struct Unit {
        let orth: String   // single letter, a digraph ("ch","ll","rr"), or a merged onset ("qu","gu","gü")
        let isVowel: Bool
        let isWeak: Bool
        let isAccented: Bool
    }

    private static let strongChars: Set<Character> = ["a", "e", "o", "á", "é", "ó"]
    private static let weakChars: Set<Character> = ["i", "u", "ü", "í", "ú"]
    private static let accentedChars: Set<Character> = ["á", "é", "í", "ó", "ú"]

    private static func isVowelChar(_ c: Character) -> Bool {
        strongChars.contains(c) || weakChars.contains(c)
    }

    // MARK: - Public entry

    static func analyze(_ rawWord: String) -> Result {
        let word = rawWord.lowercased()
        let units = tokenize(Array(word))
        guard !units.isEmpty else { return Result(ipa: "", syllables: [], stressIndex: 0) }

        let nuclei = groupNuclei(units)
        guard !nuclei.isEmpty else {
            // No vowels (rare); treat whole thing as one syllable.
            let ipa = units.map { consonantIPA(orth: $0.orth, index: 0, units: units) }.joined()
            return Result(ipa: ipa, syllables: [word], stressIndex: 0)
        }

        let syllables = assignConsonants(units: units, nuclei: nuclei)
        let stressIndex = stressedSyllable(word: word, units: units, syllables: syllables)
        let ipa = renderIPA(units: units, syllables: syllables, stressIndex: stressIndex)
        let orthSyllables = syllables.map { syl in
            syl.unitIndices.map { units[$0].orth }.joined()
        }
        return Result(ipa: ipa, syllables: orthSyllables, stressIndex: stressIndex)
    }

    // MARK: - Tokenization

    private static func tokenize(_ chars: [Character]) -> [Unit] {
        var units: [Unit] = []
        var i = 0
        let n = chars.count
        func at(_ k: Int) -> Character? { (k >= 0 && k < n) ? chars[k] : nil }

        while i < n {
            let c = chars[i]
            let next = at(i + 1)
            let after = at(i + 2)

            // Silent-u onsets: que/qui -> /k/, gue/gui -> /ɡ/, güe/güi -> /ɡw/
            if c == "q", next == "u" {
                units.append(Unit(orth: "qu", isVowel: false, isWeak: false, isAccented: false))
                i += 2; continue
            }
            if c == "g", next == "u", let a = after, a == "e" || a == "i" || a == "é" || a == "í" {
                units.append(Unit(orth: "gu", isVowel: false, isWeak: false, isAccented: false))
                i += 2; continue
            }
            if c == "g", next == "ü" {
                units.append(Unit(orth: "gü", isVowel: false, isWeak: false, isAccented: false))
                i += 2; continue
            }

            // Digraphs
            if c == "c", next == "h" {
                units.append(Unit(orth: "ch", isVowel: false, isWeak: false, isAccented: false)); i += 2; continue
            }
            if c == "l", next == "l" {
                units.append(Unit(orth: "ll", isVowel: false, isWeak: false, isAccented: false)); i += 2; continue
            }
            if c == "r", next == "r" {
                units.append(Unit(orth: "rr", isVowel: false, isWeak: false, isAccented: false)); i += 2; continue
            }

            // 'y' is a vowel only when not followed by a vowel (final, or before a consonant).
            if c == "y" {
                let isVowelHere = (next == nil) || !(isVowelChar(next!))
                if isVowelHere {
                    units.append(Unit(orth: "y", isVowel: true, isWeak: true, isAccented: false))
                } else {
                    units.append(Unit(orth: "y", isVowel: false, isWeak: false, isAccented: false))
                }
                i += 1; continue
            }

            if isVowelChar(c) {
                units.append(Unit(orth: String(c),
                                  isVowel: true,
                                  isWeak: weakChars.contains(c),
                                  isAccented: accentedChars.contains(c)))
            } else {
                units.append(Unit(orth: String(c), isVowel: false, isWeak: false, isAccented: false))
            }
            i += 1
        }
        return units
    }

    // MARK: - Nuclei (diphthong / hiatus grouping)

    /// Each nucleus is the list of vowel-unit indices that share one syllable peak.
    private static func groupNuclei(_ units: [Unit]) -> [[Int]] {
        func isWeakUnaccented(_ u: Unit) -> Bool { u.isVowel && u.isWeak && !u.isAccented }

        var nuclei: [[Int]] = []
        var current: [Int] = []
        var prev: Unit? = nil

        for (idx, u) in units.enumerated() {
            guard u.isVowel else {
                if !current.isEmpty { nuclei.append(current); current = [] }
                prev = nil
                continue
            }
            if let p = prev, current.count < 3, (isWeakUnaccented(p) || isWeakUnaccented(u)) {
                current.append(idx)   // diphthong/triphthong: same nucleus
            } else {
                if !current.isEmpty { nuclei.append(current) }
                current = [idx]       // hiatus or start: new nucleus
            }
            prev = u
        }
        if !current.isEmpty { nuclei.append(current) }
        return nuclei
    }

    // MARK: - Syllable assembly

    private struct Syllable { var unitIndices: [Int]; let nucleus: [Int] }

    private static func isValidOnsetCluster(_ a: String, _ b: String) -> Bool {
        guard b == "l" || b == "r" else { return false }
        if b == "r" { return ["p", "b", "f", "g", "c", "k", "t", "d"].contains(a) }
        return ["p", "b", "f", "g", "c", "k"].contains(a)   // tl, dl not valid onsets
    }

    private static func assignConsonants(units: [Unit], nuclei: [[Int]]) -> [Syllable] {
        var syllables: [Syllable] = nuclei.map { Syllable(unitIndices: $0, nucleus: $0) }

        // Leading consonants -> first syllable onset.
        if let firstVowel = nuclei.first?.first {
            let leading = Array(0..<firstVowel)
            syllables[0].unitIndices = leading + syllables[0].unitIndices
        }

        // Consonants between nuclei -> split into coda(prev) + onset(next).
        for i in 0..<(nuclei.count - 1) {
            let leftEnd = nuclei[i].last!
            let rightStart = nuclei[i + 1].first!
            let consonants = Array((leftEnd + 1)..<rightStart)
            guard !consonants.isEmpty else { continue }

            let k = consonants.count
            var onsetCount = 1
            if k >= 2,
               isValidOnsetCluster(units[consonants[k - 2]].orth, units[consonants[k - 1]].orth) {
                onsetCount = 2
            }
            let codaCount = k - onsetCount
            let coda = Array(consonants.prefix(codaCount))
            let onset = Array(consonants.suffix(onsetCount))
            syllables[i].unitIndices += coda
            syllables[i + 1].unitIndices = onset + syllables[i + 1].unitIndices
        }

        // Trailing consonants -> last syllable coda.
        if let lastVowel = nuclei.last?.last, lastVowel + 1 < units.count {
            let trailing = Array((lastVowel + 1)..<units.count)
            syllables[syllables.count - 1].unitIndices += trailing
        }

        // Keep each syllable's units in original order.
        for j in 0..<syllables.count { syllables[j].unitIndices.sort() }
        return syllables
    }

    // MARK: - Stress

    private static func stressedSyllable(word: String, units: [Unit], syllables: [Syllable]) -> Int {
        // 1) Written accent wins.
        for (sylIdx, syl) in syllables.enumerated() {
            if syl.nucleus.contains(where: { units[$0].isAccented }) { return sylIdx }
        }
        // 2) Default rules.
        guard syllables.count > 1 else { return 0 }
        if let last = word.last {
            if isVowelChar(last) || last == "n" || last == "s" {
                return syllables.count - 2   // paroxytone
            }
        }
        return syllables.count - 1           // oxytone
    }

    // MARK: - IPA rendering

    private static func renderIPA(units: [Unit], syllables: [Syllable], stressIndex: Int) -> String {
        var parts: [String] = []
        for syl in syllables {
            let nucleusSet = Set(syl.nucleus)
            var s = ""
            for idx in syl.unitIndices {
                let u = units[idx]
                if u.isVowel && nucleusSet.contains(idx) {
                    s += vowelIPA(units: units, nucleus: syl.nucleus, index: idx)
                } else if !u.isVowel {
                    s += consonantIPA(orth: u.orth, index: idx, units: units)
                }
            }
            parts.append(s)
        }
        var out = ""
        for (i, p) in parts.enumerated() {
            if i == 0 {
                out += (i == stressIndex ? "\u{02C8}" : "") + p
            } else {
                out += (i == stressIndex ? "\u{02C8}" : ".") + p
            }
        }
        return out
    }

    private static func vowelIPA(units: [Unit], nucleus: [Int], index: Int) -> String {
        // Determine the main (peak) vowel of this nucleus.
        func base(_ u: Unit) -> String {
            switch u.orth {
            case "a", "á": return "a"
            case "e", "é": return "e"
            case "i", "í", "y": return "i"
            case "o", "ó": return "o"
            case "u", "ú", "ü": return "u"
            default: return u.orth
            }
        }
        let mainIdx: Int = {
            if let acc = nucleus.first(where: { units[$0].isAccented }) { return acc }
            if let strong = nucleus.first(where: { !units[$0].isWeak }) { return strong }
            return nucleus.last!
        }()

        let u = units[index]
        if index == mainIdx { return base(u) }

        let isGlideU = (base(u) == "u")
        let glide = isGlideU ? "u" : "i"
        if index < mainIdx {
            return isGlideU ? "w" : "j"                 // on-glide
        } else {
            return glide + "\u{032F}"                   // off-glide (inverted breve below)
        }
    }

    private static func consonantIPA(orth: String, index: Int, units: [Unit]) -> String {
        func nextVowelChar() -> Character? {
            let n = index + 1
            guard n < units.count, units[n].isVowel else { return nil }
            return units[n].orth.first
        }
        let prevOrth = index > 0 ? units[index - 1].orth : nil

        switch orth {
        case "b", "v": return "b"
        case "c":
            if let nv = nextVowelChar(), nv == "e" || nv == "é" || nv == "i" || nv == "í" { return "s" }
            return "k"
        case "ch": return "t\u{0283}"            // tʃ
        case "d": return "d"
        case "f": return "f"
        case "g":
            if let nv = nextVowelChar(), nv == "e" || nv == "é" || nv == "i" || nv == "í" { return "x" }
            return "\u{0261}"                     // ɡ
        case "gu": return "\u{0261}"             // ɡ (silent u)
        case "gü": return "\u{0261}w"            // ɡw
        case "h": return ""                      // silent
        case "j": return "x"
        case "k": return "k"
        case "l": return "l"
        case "ll": return "\u{029D}"             // ʝ
        case "m": return "m"
        case "n": return "n"
        case "ñ": return "\u{0272}"              // ɲ
        case "p": return "p"
        case "qu": return "k"                     // silent u
        case "r":
            if index == 0 { return "r" }                          // word-initial trill
            if let p = prevOrth, p == "n" || p == "l" || p == "s" { return "r" }
            return "\u{027E}"                     // ɾ tap
        case "rr": return "r"                     // trill
        case "s": return "s"
        case "t": return "t"
        case "w": return "w"
        case "x": return "ks"
        case "y": return "\u{029D}"              // ʝ (consonantal y)
        case "z": return "s"                      // seseo
        default: return orth
        }
    }
}
