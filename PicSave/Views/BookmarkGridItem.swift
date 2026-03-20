import SwiftUI

struct BookmarkGridItem: View {

    let work: PixivWork
    let cookie: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CachedImageView(urlString: work.url, cookie: cookie)
                .frame(height: 180)
                .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(work.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(work.userName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        .onTapGesture {
            if let url = URL(string: "https://www.pixiv.net/artworks/\(work.id.value)") {
                NSWorkspace.shared.open(url)
            }
        }
        .contextMenu {
            Button("Open in Browser") {
                if let url = URL(string: "https://www.pixiv.net/artworks/\(work.id.value)") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Copy Link") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(
                    "https://www.pixiv.net/artworks/\(work.id.value)",
                    forType: .string
                )
            }
        }
    }
}
