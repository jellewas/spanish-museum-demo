import SwiftUI
import PronunciationCore

/// Bottom sheet shown when a word is tapped: word, IPA, syllables, playback, Dutch tips.
struct PronunciationSheet: View {
    let pronunciation: Pronunciation

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(pronunciation.word)
                    .font(.largeTitle.bold())
                Text("/\(pronunciation.ipa)/")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    PronunciationSpeaker.shared.speak(pronunciation.word)
                } label: {
                    Label("Luister", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    PronunciationSpeaker.shared.speak(pronunciation.word, slow: true)
                } label: {
                    Label("Langzaam", systemImage: "tortoise.fill")
                }
                .buttonStyle(.bordered)

                Button {
                    PronunciationSpeaker.shared.speakSyllables(pronunciation.syllables)
                } label: {
                    Label("Per lettergreep", systemImage: "square.split.2x1")
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 6) {
                ForEach(Array(pronunciation.syllables.enumerated()), id: \.offset) { index, syllable in
                    Text(syllable)
                        .font(.title3.weight(index == pronunciation.stressIndex ? .bold : .regular))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(index == pronunciation.stressIndex
                                    ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(pronunciation.tips, id: \.self) { tip in
                    Label(tip, systemImage: "lightbulb.fill")
                        .font(.callout)
                        .labelStyle(.titleAndIcon)
                }
            }

            Spacer()
        }
        .padding(24)
        .presentationDetents([.medium])
        .onAppear { PronunciationSpeaker.shared.speak(pronunciation.word) }
    }
}
