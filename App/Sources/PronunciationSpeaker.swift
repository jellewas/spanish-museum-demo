import AVFoundation

/// Offline Spanish text-to-speech. Spanish orthography is shallow, so speaking the
/// written word directly is accurate — no IPA needed for the audio itself.
final class PronunciationSpeaker {
    static let shared = PronunciationSpeaker()
    private let synthesizer = AVSpeechSynthesizer()

    // Neutral Latin-American voice (seseo), matching the G2P conventions; falls back to any es voice.
    private var voice: AVSpeechSynthesisVoice? {
        AVSpeechSynthesisVoice(language: "es-MX") ?? AVSpeechSynthesisVoice(language: "es-ES")
    }

    func speak(_ text: String, slow: Bool = false) {
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance(text, slow: slow))
    }

    /// Speak syllable by syllable with short pauses, for clear articulation.
    func speakSyllables(_ syllables: [String]) {
        synthesizer.stopSpeaking(at: .immediate)
        for syllable in syllables {
            let u = utterance(syllable, slow: true)
            u.postUtteranceDelay = 0.25
            synthesizer.speak(u)
        }
    }

    private func utterance(_ text: String, slow: Bool) -> AVSpeechUtterance {
        let u = AVSpeechUtterance(string: text)
        u.voice = voice
        u.rate = slow ? AVSpeechUtteranceMinimumSpeechRate * 1.4
                      : AVSpeechUtteranceDefaultSpeechRate * 0.9
        return u
    }
}
