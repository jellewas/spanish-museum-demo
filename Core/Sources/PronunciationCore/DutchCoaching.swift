/// Deterministic, offline pronunciation tips in Dutch, keyed on Spanish spelling
/// features that predictably trip up Dutch (L1) speakers learning Spanish.
enum DutchCoaching {

    /// Returns at most 3 tips: up to 2 feature-specific tips, always followed by a stress tip.
    static func tips(for rawWord: String, stressedSyllable: String) -> [String] {
        let w = Array(rawWord.lowercased())

        func has(_ s: String) -> Bool { contains(w, Array(s)) }
        func hasCeCi() -> Bool { ["ce", "ci", "cé", "cí"].contains { has($0) } }
        func hasGeGi() -> Bool { ["ge", "gi", "gé", "gí"].contains { has($0) } }

        // Ordered by salience; first matches win.
        var features: [String] = []
        func add(_ tip: String) { if features.count < 2 { features.append(tip) } }

        if has("j") || hasGeGi() {
            add("De Spaanse 'j' en de 'g' (voor e/i) klink je als de Nederlandse harde g, zoals in 'lachen'.")
        }
        if has("z") || hasCeCi() {
            add("'z', 'ce' en 'ci' spreek je uit als een gewone 's' — niet als de Engelse 'th'.")
        }
        if has("rr") {
            add("Rol de dubbele 'rr' met een trillende tongpunt, langer dan een Nederlandse r.")
        }
        if has("ll") {
            add("'ll' klinkt als de Nederlandse 'j', zoals in 'ja'.")
        }
        if has("ñ") {
            add("'ñ' spreek je uit als 'nj', zoals in 'oranje'.")
        }
        if has("v") {
            add("De 'v' klinkt in het Spaans als een 'b'.")
        }
        if has("qu") {
            add("'qu' klink je als 'k'; de 'u' blijft stil.")
        }
        if hasSilentH(w) {
            add("De 'h' is stom — die spreek je niet uit.")
        }

        if features.isEmpty {
            features.append("Spreek elke klinker helder en kort uit; vermijd de Nederlandse stomme e (de 'sjwa').")
        }

        return features + ["Klemtoon op '\(stressedSyllable)'."]
    }

    /// Substring search over Characters (avoids Foundation).
    private static func contains(_ haystack: [Character], _ needle: [Character]) -> Bool {
        guard !needle.isEmpty, haystack.count >= needle.count else { return false }
        for start in 0...(haystack.count - needle.count) {
            var matched = true
            for k in 0..<needle.count where haystack[start + k] != needle[k] { matched = false; break }
            if matched { return true }
        }
        return false
    }

    /// True if there's an 'h' that is not part of the 'ch' digraph.
    private static func hasSilentH(_ w: [Character]) -> Bool {
        for (i, c) in w.enumerated() where c == "h" {
            if i == 0 || w[i - 1] != "c" { return true }
        }
        return false
    }
}
