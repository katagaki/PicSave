import AppKit
import CryptoKit
import Foundation

actor ImageCache {

    static let shared = ImageCache()

    private var inMemoryCache: [String: NSImage] = [:]

    private var cacheDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("PicSave/ImageCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func cacheFile(for urlString: String) -> URL {
        let filename = URL(string: urlString)?.lastPathComponent ?? {
            let hash = SHA256.hash(data: Data(urlString.utf8))
            return hash.map { String(format: "%02x", $0) }.joined()
        }()
        return cacheDirectory.appendingPathComponent(filename)
    }

    func image(for urlString: String, cookie: String) async -> NSImage? {
        // Check in-memory cache
        if let cached = inMemoryCache[urlString] {
            return cached
        }

        let file = cacheFile(for: urlString)

        // Check disk cache
        if FileManager.default.fileExists(atPath: file.path),
           let image = NSImage(contentsOf: file) {
            inMemoryCache[urlString] = image
            return image
        }

        // Fetch from network
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.setValue(cookie, forHTTPHeaderField: "Cookie")
        request.setValue("https://www.pixiv.net/", forHTTPHeaderField: "Referer")
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.3.1 Safari/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let image = NSImage(data: data) else {
                return nil
            }
            // Save to disk
            try? data.write(to: file, options: .atomic)
            inMemoryCache[urlString] = image
            return image
        } catch {
            return nil
        }
    }
}
