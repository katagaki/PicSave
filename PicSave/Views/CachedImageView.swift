import SwiftUI

struct CachedImageView: View {

    let urlString: String
    let cookie: String

    @State private var image: XPImage?
    @State private var isLoading = false

    private func imageView(_ xpImage: XPImage) -> Image {
#if os(iOS)
        Image(uiImage: xpImage)
#elseif os(macOS)
        Image(nsImage: xpImage)
#endif
    }

    var body: some View {
        Group {
            if let image {
                imageView(image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .onAppear {
            guard image == nil, !isLoading else { return }
            isLoading = true
            Task {
                let loaded = await ImageCache.shared.image(for: urlString, cookie: cookie)
                await MainActor.run {
                    image = loaded
                    isLoading = false
                }
            }
        }
    }
}
