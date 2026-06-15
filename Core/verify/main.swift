// Standalone verifier (mirrors the XCTest cases) for environments without full Xcode.
// Compile: swiftc Sources/PronunciationCore/*.swift verify/main.swift -o /tmp/verify
var failures = 0
func check(_ label: String, _ got: String, _ want: String) {
    if got != want { failures += 1; print("FAIL \(label): got \(got)  want \(want)") }
}
func checkTrue(_ label: String, _ cond: Bool) {
    if !cond { failures += 1; print("FAIL \(label)") }
}

let ipaCases: [(String, String)] = [
    ("museo",    "mu\u{02C8}se.o"),
    ("jamón",    "xa\u{02C8}mon"),
    ("gracias",  "\u{02C8}\u{0261}\u{027E}a.sjas"),
    ("niño",     "\u{02C8}ni.\u{0272}o"),
    ("cerveza",  "se\u{027E}\u{02C8}be.sa"),
    ("llave",    "\u{02C8}\u{029D}a.be"),
    ("guitarra", "\u{0261}i\u{02C8}ta.ra"),
    ("perro",    "\u{02C8}pe.ro"),
    ("pero",     "\u{02C8}pe.\u{027E}o"),
    ("español",  "es.pa\u{02C8}\u{0272}ol"),
    ("ciudad",   "sju\u{02C8}dad"),
    ("corazón",  "ko.\u{027E}a\u{02C8}son"),
    ("hola",     "\u{02C8}o.la"),
    ("queso",    "\u{02C8}ke.so"),
    ("agua",     "\u{02C8}a.\u{0261}wa"),
    ("buenos",   "\u{02C8}bwe.nos"),
    ("día",      "\u{02C8}di.a"),
]
for (w, want) in ipaCases { check("IPA \(w)", Pronouncer.pronounce(w).ipa, want) }

check("syll museo",    Pronouncer.pronounce("museo").syllables.joined(separator: "-"), "mu-se-o")
check("syll español",  Pronouncer.pronounce("español").syllables.joined(separator: "-"), "es-pa-ñol")
check("syll guitarra", Pronouncer.pronounce("guitarra").syllables.joined(separator: "-"), "gui-ta-rra")
check("syll gracias",  Pronouncer.pronounce("gracias").syllables.joined(separator: "-"), "gra-cias")

check("stress museo",   "\(Pronouncer.pronounce("museo").stressIndex)", "1")
check("stress jamón",   "\(Pronouncer.pronounce("jamón").stressIndex)", "1")
check("stress español", "\(Pronouncer.pronounce("español").stressIndex)", "2")
check("stress corazón", "\(Pronouncer.pronounce("corazón").stressIndex)", "2")

let cerveza = Pronouncer.pronounce("cerveza").tips
checkTrue("seseo tip",  cerveza.contains { $0.contains("gewone 's'") })
checkTrue("v→b tip",    cerveza.contains { $0.contains("als een 'b'") })
checkTrue("stress last", cerveza.last?.hasPrefix("Klemtoon op") ?? false)
checkTrue("jota tip",   Pronouncer.pronounce("jamón").tips.contains { $0.contains("harde g") })
checkTrue("trill tip",  Pronouncer.pronounce("guitarra").tips.contains { $0.contains("trillende tongpunt") })
for w in ["cerveza", "guitarra", "jamón", "español", "museo"] {
    checkTrue("≤3 tips \(w)", Pronouncer.pronounce(w).tips.count <= 3)
}

if failures == 0 {
    print("ALL PASS (\(ipaCases.count) IPA + syllable/stress/coaching checks)")
} else {
    print("\(failures) FAILURE(S)")
}
