# Pronto — Spanish Museum Pronunciation Demo

Offline-first iOS demo. Point your camera at Spanish text (a museum placard, a
menu, a sign), tap a word, and hear it pronounced correctly — with IPA,
syllable breakdown, and pronunciation tips in Dutch for the learner.

> Concept demo for a language-learning app whose edge is "you only speak to an
> AI that corrects you." **This demo is the adjacent travel / offline feature —
> snap-and-hear pronunciation — not the core record-yourself correction loop.**
> The point it proves: the hard linguistics (correct Spanish IPA, syllabification,
> stress, and Dutch-specific coaching) run fully on-device, no model, no signal.

## Try it in 30 seconds (web)

The `web/` folder is a self-contained browser version — the quickest way to see
it. It must be **served over http** (the OCR worker won't load from `file://`):

```sh
cd web
python3 -m http.server 8000
# open http://localhost:8000
```

A sample museum placard ("Velorio de un Angelito") is pre-loaded — tap any word
to hear it, see IPA + syllables, and get Dutch pronunciation tips. Use
**📷 Foto kiezen** to OCR your own photo, or **✏️ Eigen tekst** to paste text.
Toggle **Offline / Online** to switch the translation source (audio is always
offline). Or just publish `web/` to GitHub Pages and share the URL.

## What works offline (no network)

_(This list describes the iOS app. The web demo mirrors the same engine; its OCR
uses Tesseract.js with the bundled `spa.traineddata` model — the Tesseract runtime
itself still loads from a CDN, so the browser OCR needs a connection on first run.)_

- **OCR** — Apple Vision, on-device, per-word bounding boxes.
- **Pronunciation** — rule-based Spanish G2P (neutral Latin-American: *seseo*,
  *yeísmo*) producing IPA + syllabification + stress. No model, no network.
- **Audio** — `AVSpeechSynthesizer` (Spanish voice), normal / slow / per-syllable.
- **Coaching** — deterministic Dutch tips keyed on the spelling features that trip
  up Dutch speakers (jota = harde g, *v* = *b*, *seseo*, rolling *rr*, *ñ*, …).

Scope of v1: **pronunciation playback only.** The record-yourself-and-get-corrected
loop (the company's core differentiator) is intentionally out of scope here.

## Layout

```
spanish-museum-demo/
├── Core/                     # Pure-Swift linguistics engine (no Foundation, no UIKit)
│   ├── Sources/PronunciationCore/
│   │   ├── SpanishPhonology.swift   # G2P: IPA, syllables, stress
│   │   ├── DutchCoaching.swift      # Dutch contrastive tips
│   │   └── Pronouncer.swift         # public API -> Pronunciation
│   ├── Tests/                       # XCTest cases
│   └── verify/main.swift            # standalone verifier (see below)
├── App/                      # SwiftUI iOS app
│   ├── Sources/
│   └── project.yml           # XcodeGen manifest
├── web/                      # self-contained browser demo (see "Try it" above)
│   ├── index.html            # UI + OCR + tappable text
│   ├── engine.js             # JS port of the Swift linguistics engine
│   ├── dict.js               # offline ES→NL glossary
│   └── spa.traineddata       # bundled Tesseract Spanish OCR model
└── skills/karpathy-guidelines/      # coding-standards skill
```

## Build the app

Requires **full Xcode** (Command Line Tools alone can't build an iOS app).

```sh
brew install xcodegen          # one-time
cd App
xcodegen generate             # creates SpanishMuseumDemo.xcodeproj
open SpanishMuseumDemo.xcodeproj
```

Run on a **real device** to use the camera. On the **simulator**, use the
"Bibliotheek" button to pick a photo of Spanish text from the photo library.

No XcodeGen? Create a new iOS App in Xcode, add the files in `App/Sources/`, add
`../Core` as a local Swift package dependency, and copy the `NSCameraUsageDescription`
/ `NSPhotoLibraryUsageDescription` keys into Info.plist.

## Verify the linguistics core

`swift test` is currently blocked by a Command Line Tools / SwiftPM toolchain
mismatch on this machine. Until full Xcode is installed, verify the engine with
the standalone runner (mirrors the XCTest cases):

```sh
cd Core
swiftc Sources/PronunciationCore/*.swift verify/main.swift -o /tmp/verify && /tmp/verify
# -> ALL PASS (17 IPA + syllable/stress/coaching checks)
```

Once full Xcode is present, `cd Core && swift test` runs the same checks via XCTest.
