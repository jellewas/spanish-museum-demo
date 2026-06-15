import Vision
import UIKit

/// One recognized word and its location in the image (normalized, Vision's
/// bottom-left origin coordinate space).
struct RecognizedWord: Identifiable {
    let id = UUID()
    let text: String
    let boundingBox: CGRect
}

/// Offline OCR via the Vision framework, returning per-word bounding boxes.
enum TextRecognizer {

    static func recognize(_ image: UIImage, completion: @escaping ([RecognizedWord]) -> Void) {
        guard let cgImage = image.cgImage else { completion([]); return }

        let request = VNRecognizeTextRequest { request, _ in
            var words: [RecognizedWord] = []
            for observation in (request.results as? [VNRecognizedTextObservation] ?? []) {
                guard let candidate = observation.topCandidates(1).first else { continue }
                let string = candidate.string
                for range in wordRanges(in: string) {
                    guard let rect = try? candidate.boundingBox(for: range) else { continue }
                    words.append(RecognizedWord(text: String(string[range]),
                                                boundingBox: rect.boundingBox))
                }
            }
            DispatchQueue.main.async { completion(words) }
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["es-ES"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage,
                                            orientation: cgOrientation(image.imageOrientation),
                                            options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    /// Split a recognized line into word ranges (letters only; drops surrounding punctuation).
    private static func wordRanges(in s: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var i = s.startIndex
        while i < s.endIndex {
            while i < s.endIndex, !s[i].isLetter { i = s.index(after: i) }
            guard i < s.endIndex else { break }
            var j = i
            while j < s.endIndex, s[j].isLetter { j = s.index(after: j) }
            ranges.append(i..<j)
            i = j
        }
        return ranges
    }

    private static func cgOrientation(_ o: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch o {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
