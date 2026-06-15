// Pure-Swift CLI used by demo.sh. Prints machine-readable analysis (no Foundation).
// Usage: spanishcli <word> [<word> ...]
for word in CommandLine.arguments.dropFirst() {
    let p = Pronouncer.pronounce(word)
    print("IPA|\(p.ipa)")
    print("SYL|\(p.syllables.joined(separator: " "))")
    print("STR|\(p.stressIndex)")
    for tip in p.tips { print("TIP|\(tip)") }
    print("END|")
}
