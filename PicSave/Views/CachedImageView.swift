import SwiftUI

struct CachedImageView: View {

    let urlString: String
    let cookie: String

    @State private var image: NSImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
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
