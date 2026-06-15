import XCTest
@testable import PronunciationCore

final class SpanishPhonologyTests: XCTestCase {

    // Hand-verified broad IPA (neutral Latin-American Spanish: seseo + yeismo).
    // Special glyphs via escapes so expectations are unambiguous:
    //   ˈ \u{02C8}  ɡ \u{0261}  ɾ \u{027E}  ɲ \u{0272}  ʝ \u{029D}  tʃ "t\u{0283}"  off-glide "\u{032F}"
    func testIPA() {
        let cases: [(String, String)] = [
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
        for (word, expected) in cases {
            XCTAssertEqual(Pronouncer.pronounce(word).ipa, expected, "IPA mismatch for '\(word)'")
        }
    }

    func testSyllabification() {
        XCTAssertEqual(Pronouncer.pronounce("museo").syllables, ["mu", "se", "o"])
        XCTAssertEqual(Pronouncer.pronounce("español").syllables, ["es", "pa", "ñol"])
        XCTAssertEqual(Pronouncer.pronounce("guitarra").syllables, ["gui", "ta", "rra"])
        XCTAssertEqual(Pronouncer.pronounce("gracias").syllables, ["gra", "cias"])
    }

    func testStress() {
        XCTAssertEqual(Pronouncer.pronounce("museo").stressIndex, 1)    // penult, ends in vowel
        XCTAssertEqual(Pronouncer.pronounce("jamón").stressIndex, 1)    // written accent
        XCTAssertEqual(Pronouncer.pronounce("español").stressIndex, 2)  // oxytone, ends in 'l'
        XCTAssertEqual(Pronouncer.pronounce("corazón").stressIndex, 2)  // written accent beats default
    }
}

final class DutchCoachingTests: XCTestCase {
    func testFeatureTipsAndStressAlwaysPresent() {
        let cerveza = Pronouncer.pronounce("cerveza").tips
        XCTAssertTrue(cerveza.contains { $0.contains("gewone 's'") }, "expected seseo tip")
        XCTAssertTrue(cerveza.contains { $0.contains("als een 'b'") }, "expected v→b tip")
        XCTAssertTrue(cerveza.last?.hasPrefix("Klemtoon op") ?? false, "stress tip must be last")

        let jamon = Pronouncer.pronounce("jamón").tips
        XCTAssertTrue(jamon.contains { $0.contains("harde g") }, "expected jota tip")

        let guitarra = Pronouncer.pronounce("guitarra").tips
        XCTAssertTrue(guitarra.contains { $0.contains("trillende tongpunt") }, "expected rr trill tip")
    }

    func testCapAtThreeTips() {
        for word in ["cerveza", "guitarra", "jamón", "español", "museo"] {
            XCTAssertLessThanOrEqual(Pronouncer.pronounce(word).tips.count, 3, "too many tips for '\(word)'")
        }
    }
}
