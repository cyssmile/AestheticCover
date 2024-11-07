/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main view.
*/

import SwiftUI

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var url: URL?
    @Environment(\.presentationMode) var presentationMode

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        @Binding var url: URL?

        init(url: Binding<URL?>) {
            _url = url
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                url = videoURL
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(url: $url)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"]
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

struct MainView: View {
    /// The array that stores the top-rated thumbnails.
    @State private var thumbnails: [Thumbnail] = []

    /// The Boolean value that tracks whether to show the file importer.
    @State private var showFileImporter: Bool = false

    /// The progression of the video that processes.
    @State private var progress: Float = 0

    /// The spacing value for the vertical stack.
    let spacing: CGFloat = 20

    @State private var videoURL: URL?
    @State private var showingVideoPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: spacing) {
                // Display a text and a button if there is no video file.
                if videoURL == nil {
                    Text(LocalizedStringKey("generateImageDesc"))
                        .font(.title)
                        .multilineTextAlignment(.center)

                    /// The button that opens the file importer.
                    Button(LocalizedStringKey("selectButtonDesc")) {
                        showingVideoPicker = true
                    }.padding(5)
                    .sheet(isPresented: $showingVideoPicker) {
                                    VideoPicker(url: $videoURL)
                                }
                    
                } else {
                    // Display the load animation if `thumbnails` is empty.
                    if thumbnails.isEmpty {
                        Text("Processing...")
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .frame(width: 300)
                            .task {
                                if let url = videoURL {
                                    // Process the video with the url of the video.
                                    thumbnails = await processVideo(for: url, progression: $progress)
                                }
                            }
                    } else {
                        // Navigate to the results when the video fully processes.
                        ResultView(topThumbnails: thumbnails, tryAgain: reset)
                    }
                }
            }
        }
        .navigationTitle("Generate Video Thumbnails")
    }

    /// Reset the video file and the thumbnails.
    func reset() {
        videoURL = nil
        thumbnails.removeAll()
        progress = 0
        showingVideoPicker = false
    }
}

#Preview {
    MainView()
}
