import Foundation

class BookmarkCache {

    static let shared = BookmarkCache()

    private var cacheDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let cacheDir = appSupport.appendingPathComponent("PicSave", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        return cacheDir
    }

    private var cacheFile: URL {
        cacheDirectory.appendingPathComponent("bookmarks.json")
    }

    func load() -> [PixivWork]? {
        guard FileManager.default.fileExists(atPath: cacheFile.path) else { return nil }
        do {
            let data = try Data(contentsOf: cacheFile)
            return try JSONDecoder().decode([PixivWork].self, from: data)
        } catch {
            return nil
        }
    }

    func save(_ works: [PixivWork]) {
        do {
            let data = try JSONEncoder().encode(works)
            try data.write(to: cacheFile, options: .atomic)
        } catch {
            print("Failed to save cache: \(error)")
        }
    }

    func clear() {
        try? FileManager.default.removeItem(at: cacheFile)
    }
}
