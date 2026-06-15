#!/bin/bash
# Runnable terminal demo of the Spanish-museum pronunciation engine.
# Shows IPA + syllables + Dutch coaching AND speaks the word aloud (offline).
#
#   ./demo.sh "El museo tiene una guitarra"   # one-shot: treat as OCR'd sign text
#   ./demo.sh                                  # interactive: type a word, hear it
#
# Audio uses macOS `say` (Paulina = es_MX, neutral seseo) — stands in for the
# app's AVSpeechSynthesizer. OCR/camera are the only iOS-only pieces.

set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
CORE="$ROOT/Core"
BIN="$ROOT/.bin/spanishcli"
VOICE="Paulina"        # es_MX, seseo — matches the G2P conventions

# Build the analyzer if needed (pure Swift, no Foundation -> compiles under CLT).
if [ ! -x "$BIN" ]; then
    echo "Building analyzer..."
    mkdir -p "$ROOT/.bin"
    swiftc "$CORE"/Sources/PronunciationCore/*.swift "$CORE"/cli/main.swift -o "$BIN"
fi

say_word()   { say -v "$VOICE" "$1" >/dev/null 2>&1 || true; }
say_slow()   { say -v "$VOICE" -r 90 "$1" >/dev/null 2>&1 || true; }

show_word() {
    local word="$1" full="$2"
    local out ipa syl str
    out="$("$BIN" "$word")"
    ipa="$(printf '%s\n' "$out" | sed -n 's/^IPA|//p')"
    syl="$(printf '%s\n' "$out" | sed -n 's/^SYL|//p')"
    str="$(printf '%s\n' "$out" | sed -n 's/^STR|//p')"

    # Build syllable display with the stressed one in [brackets].
    local i=0 disp="" sep=""
    for s in $syl; do
        if [ "$i" -eq "$str" ]; then disp="$disp$sep[$s]"; else disp="$disp$sep$s"; fi
        sep="-"; i=$((i+1))
    done

    printf '\n  \033[1m%s\033[0m   /%s/   %s\n' "$word" "$ipa" "$disp"
    printf '%s\n' "$out" | sed -n 's/^TIP|/     • /p'

    if [ "$full" = "full" ]; then
        echo "     🔊 normaal..."   ; say_word "$word"
        echo "     🐢 langzaam..."  ; say_slow "$word"
        echo "     🔡 per lettergreep..."
        for s in $syl; do printf '        %s\n' "$s"; say_slow "$s"; sleep 0.15; done
    else
        say_word "$word"
    fi
}

interactive() {
    echo "Typ een Spaans woord (of 'q' om te stoppen):"
    while true; do
        printf '> '
        read -r word || break
        [ "$word" = "q" ] && break
        [ -z "$word" ] && continue
        show_word "$word" full
    done
}

oneshot() {
    local phrase="$*"
    echo "============================================================"
    echo " 📷  Foto van een bordje  →  OCR herkende tekst:"
    echo "     \"$phrase\""
    echo " 👆  Tik op een woord om de uitspraak te horen:"
    echo "============================================================"
    # First word gets the full treatment (slow + per-syllable); rest are compact.
    local first=1
    for word in $phrase; do
        # keep only letters (drop punctuation), skip empties
        clean="$(printf '%s' "$word" | tr -cd '[:alpha:]áéíóúñü')"
        [ -z "$clean" ] && continue
        if [ "$first" = "1" ]; then show_word "$clean" full; first=0; else show_word "$clean" compact; fi
    done
    echo ""
}

if [ "$#" -ge 1 ]; then oneshot "$@"; else interactive; fi
