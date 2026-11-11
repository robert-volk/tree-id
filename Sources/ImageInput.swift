import SwiftUI
import PhotosUI
import UIKit

extension UIImage {
    /// Redraws upright at scale 1, shrinking so the longest side is at most `maxSide` pixels.
    func normalized(maxSide: CGFloat) -> UIImage {
        let s = min(1, maxSide / max(size.width, size.height))
        let newSize = CGSize(width: (size.width * s).rounded(), height: (size.height * s).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    func jpeg(maxSide: CGFloat, quality: CGFloat) -> Data? {
        normalized(maxSide: maxSide).jpegData(compressionQuality: quality)
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { parent.onImage(img) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

/// "Take photo" + "Choose photo" buttons. Delivers an upright, size-capped image.
struct PhotoSourceBar: View {
    let onPick: (UIImage) -> Void
    @State private var showCamera = false
    @State private var item: PhotosPickerItem?

    var body: some View {
        HStack(spacing: 10) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button { showCamera = true } label: { Label("Take photo", systemImage: "camera") }
                    .buttonStyle(FieldButtonStyle(filled: true))
            }
            PhotosPicker(selection: $item, matching: .images) {
                Label("Choose photo", systemImage: "photo")
            }
            .buttonStyle(FieldButtonStyle(filled: false))
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { onPick($0.normalized(maxSide: 2000)) }
                .ignoresSafeArea()
        }
        .onChange(of: item) { _, new in
            guard let new else { return }
            Task {
                if let data = try? await new.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    onPick(img.normalized(maxSide: 2000))
                }
                item = nil
            }
        }
    }
}
