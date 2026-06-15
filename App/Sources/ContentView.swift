import SwiftUI
import PhotosUI
import PronunciationCore

struct ContentView: View {
    @State private var image: UIImage?
    @State private var words: [RecognizedWord] = []
    @State private var selected: Pronunciation?
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var isRecognizing = false

    var body: some View {
        NavigationStack {
            Group {
                if let image {
                    WordOverlayView(image: image, words: words) { tappedWord in
                        selected = Pronouncer.pronounce(tappedWord)
                    }
                    .overlay(alignment: .top) { hint }
                } else {
                    placeholder
                }
            }
            .navigationTitle("Pronto")
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Bibliotheek", systemImage: "photo.on.rectangle")
                    }
                    Spacer()
                    Button {
                        showCamera = true
                    } label: {
                        Label("Camera", systemImage: "camera.fill")
                    }
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker { picked in setImage(picked) }
                .ignoresSafeArea()
        }
        .sheet(item: $selected) { PronunciationSheet(pronunciation: $0) }
        .onChange(of: photoItem) { _, newItem in
            Task { await loadPickedPhoto(newItem) }
        }
    }

    private var hint: some View {
        Text(isRecognizing ? "Tekst herkennen…"
                           : (words.isEmpty ? "Geen tekst gevonden" : "Tik op een woord"))
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.top, 8)
    }

    private var placeholder: some View {
        ContentUnavailableView(
            "Spaanse uitspraak",
            systemImage: "text.viewfinder",
            description: Text("Fotografeer of kies een foto met Spaanse tekst. Tik daarna op een woord om de uitspraak te horen.")
        )
    }

    private func loadPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }
        setImage(uiImage)
    }

    private func setImage(_ uiImage: UIImage) {
        image = uiImage
        words = []
        selected = nil
        isRecognizing = true
        TextRecognizer.recognize(uiImage) { recognized in
            words = recognized
            isRecognizing = false
        }
    }
}
