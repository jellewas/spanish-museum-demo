import SwiftUI

/// Draws the photo with a tappable highlight box over each recognized word.
struct WordOverlayView: View {
    let image: UIImage
    let words: [RecognizedWord]
    let onTap: (String) -> Void

    var body: some View {
        GeometryReader { geo in
            let frame = aspectFitRect(imageSize: image.size, in: geo.size)
            ZStack(alignment: .topLeading) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)

                ForEach(words) { word in
                    let r = viewRect(for: word.boundingBox, in: frame)
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.18))
                        .overlay(Rectangle().stroke(Color.accentColor, lineWidth: 1))
                        .frame(width: r.width, height: r.height)
                        .position(x: r.midX, y: r.midY)
                        .onTapGesture { onTap(word.text) }
                }
            }
        }
    }

    /// The rect the aspect-fit image actually occupies inside the view.
    private func aspectFitRect(imageSize: CGSize, in container: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }
        let scale = min(container.width / imageSize.width, container.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let origin = CGPoint(x: (container.width - size.width) / 2,
                             y: (container.height - size.height) / 2)
        return CGRect(origin: origin, size: size)
    }

    /// Convert a Vision box (normalized, bottom-left origin) to SwiftUI view coordinates.
    private func viewRect(for box: CGRect, in frame: CGRect) -> CGRect {
        let w = box.width * frame.width
        let h = box.height * frame.height
        let x = frame.minX + box.minX * frame.width
        let y = frame.minY + (1 - box.maxY) * frame.height   // flip Y
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
