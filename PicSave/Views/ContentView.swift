import SwiftUI

extension KeyPath: @retroactive @unchecked Sendable {}

struct ContentView: View {

    @AppStorage("pixivUserId") var userId: String = ""
    @AppStorage("pixivSessionCookie") var sessionCookie: String = ""

    @State var works: [PixivWork] = []
    @State var total: Int = 0
    @State var loadedCount: Int = 0
    @State var isLoading: Bool = false
    @State var errorMessage: String?
    @State var searchText: String = ""
    @State var debouncedSearchText: String = ""
    @State var searchDebounceTask: Task<Void, Never>?
    @State var viewMode: ViewMode = .grid
    @State var sortOrder = [KeyPathComparator(\PixivWork.createDate, order: .reverse)]
    @State var selectedWorkID: FlexibleString?

    enum ViewMode: String {
        case grid, table
    }

    let pageSize = 48

    var filteredWorks: [PixivWork] {
        let sorted = works.sorted { $0.createDate > $1.createDate }
        guard !debouncedSearchText.isEmpty else { return sorted }
        let query = debouncedSearchText.lowercased()
        return sorted.filter { work in
            work.title.lowercased().contains(query)
            || work.tags.contains(where: { $0.lowercased().contains(query) })
        }
    }

    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink {
                    bookmarksView
                } label: {
                    Label("Bookmarks", systemImage: "bookmark.fill")
                }
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            bookmarksView
        }
    }

    var bookmarksView: some View {
        VStack(spacing: 0) {
            if let errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(errorMessage)
                    Spacer()
                    Button("Dismiss") {
                        self.errorMessage = nil
                    }
                }
                .padding(8)
                .background(.red.opacity(0.1))
            }

            switch viewMode {
            case .grid:
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 180, maximum: 250))],
                        spacing: 12
                    ) {
                        ForEach(filteredWorks) { work in
                            BookmarkGridItem(work: work, cookie: sessionCookie)
                        }
                    }
                    .padding(12)
                }
            case .table:
                Table(filteredWorks, selection: $selectedWorkID, sortOrder: $sortOrder) {
                    TableColumn("Title", value: \.title)
                        .width(min: 150, ideal: 250)
                    TableColumn("Artist", value: \.userName)
                        .width(min: 100, ideal: 150)
                    TableColumn("Pages") { work in
                        Text("\(work.pageCount)")
                    }
                    .width(50)
                    TableColumn("Size") { work in
                        Text("\(work.width)×\(work.height)")
                    }
                    .width(80)
                    TableColumn("Tags") { work in
                        Text(work.tags.joined(separator: ", "))
                            .lineLimit(1)
                    }
                    .width(min: 150, ideal: 250)
                    TableColumn("Date", value: \.createDate) { work in
                        Text(formattedDate(work.createDate))
                    }
                    .width(min: 100, ideal: 140)
                    TableColumn("AI") { work in
                        Text(work.aiType == 2 ? "Yes" : "No")
                    }
                    .width(40)
                }
                .onChange(of: sortOrder) {
                    works.sort(using: sortOrder)
                }
                .onChange(of: selectedWorkID) {
                    if let id = selectedWorkID,
                       let url = URL(string: "https://www.pixiv.net/artworks/\(id.value)") {
                        NSWorkspace.shared.open(url)
                        selectedWorkID = nil
                    }
                }
            }

            Divider()

            HStack {
                if isLoading {
                    ProgressView(value: Double(loadedCount), total: Double(max(total, 1)))
                        .frame(width: 100)
                    Text("\(loadedCount)/\(total)")
                        .font(.caption)
                        .monospacedDigit()
                } else {
                    Text(debouncedSearchText.isEmpty
                         ? "\(works.count) bookmarks"
                         : "\(filteredWorks.count) of \(works.count) bookmarks")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                Spacer()
            }
            .padding(8)
        }
        .searchable(text: $searchText, prompt: "Search by title or tag")
        .onChange(of: searchText) {
            searchDebounceTask?.cancel()
            searchDebounceTask = Task {
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { return }
                debouncedSearchText = searchText
            }
        }
        .navigationTitle("Bookmarks")
        .toolbar {
            ToolbarItem {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            ToolbarItem {
                Button {
                    viewMode = viewMode == .grid ? .table : .grid
                } label: {
                    Label(
                        viewMode == .grid ? "Table View" : "Grid View",
                        systemImage: viewMode == .grid ? "list.bullet" : "square.grid.2x2"
                    )
                }
            }
            ToolbarItem {
                Button {
                    Task { await refreshBookmarks() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .task {
            if works.isEmpty {
                await loadBookmarks()
            }
        }
    }

    func loadBookmarks() async {
        if let cached = BookmarkCache.shared.load() {
            works = cached
            total = cached.count
            loadedCount = cached.count
            return
        }
        await fetchAllBookmarks()
    }

    func refreshBookmarks() async {
        BookmarkCache.shared.clear()
        works = []
        total = 0
        loadedCount = 0
        await fetchAllBookmarks()
    }

    func fetchAllBookmarks() async {
        guard !userId.isEmpty, !sessionCookie.isEmpty else {
            errorMessage = "Please log in to Pixiv from Settings."
            return
        }

        isLoading = true
        errorMessage = nil
        var allWorks: [PixivWork] = []

        do {
            let firstResponse = try await PixivService.shared.fetchBookmarks(
                userId: userId,
                cookie: sessionCookie,
                offset: 0,
                limit: pageSize
            )
            total = firstResponse.body.total
            allWorks.append(contentsOf: firstResponse.body.works)
            loadedCount = allWorks.count
            works = allWorks

            var offset = pageSize
            while offset < total {
                try await Task.sleep(for: .seconds(1))
                let response = try await PixivService.shared.fetchBookmarks(
                    userId: userId,
                    cookie: sessionCookie,
                    offset: offset,
                    limit: pageSize
                )
                allWorks.append(contentsOf: response.body.works)
                loadedCount = allWorks.count
                works = allWorks
                offset += pageSize
            }

            BookmarkCache.shared.save(allWorks)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func formattedDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: isoString) else {
            return isoString
        }
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .short
        return display.string(from: date)
    }
}
