import SwiftUI

struct BookmarkGridItem: View {

    @Environment(\.openURL) private var openURL

    let work: PixivWork
    let cookie: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CachedImageView(urlString: work.url, cookie: cookie)
#if os(iOS)
                .frame(height: 110)
#else
                .frame(height: 120)
#endif
                .clipped()

            VStack(alignment: .leading, spacing: 1) {
                Text(work.title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(work.userName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        }
        .background {
#if os(iOS)
            Color(.secondarySystemBackground)
#else
            Color(.controlBackgroundColor)
#endif
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.separator, lineWidth: 0.3)
        )
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        .onTapGesture {
            openIllust(id: work.id.value)
        }
        .contextMenu {
#if os(iOS)
            Button(String(localized: "Bookmark.OpenInPixiv")) {
                openIllust(id: work.id.value)
            }
#endif
            Button(String(localized: "Bookmark.OpenInBrowser")) {
                if let url = URL(string: "https://www.pixiv.net/artworks/\(work.id.value)") {
                    openURL(url)
                }
            }
            Button(String(localized: "Bookmark.CopyLink")) {
                let link = "https://www.pixiv.net/artworks/\(work.id.value)"
#if os(iOS)
                UIPasteboard.general.string = link
#elseif os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(link, forType: .string)
#endif
            }
        }
    }

    private func openIllust(id: String) {
#if os(iOS)
        let appURL = URL(string: "pixiv://illusts/\(id)")!
        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let webURL = URL(string: "https://www.pixiv.net/artworks/\(id)") {
            openURL(webURL)
        }
#elseif os(macOS)
        if let url = URL(string: "https://www.pixiv.net/artworks/\(id)") {
            openURL(url)
        }
#endif
    }
}
