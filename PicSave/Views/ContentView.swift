import SwiftUI

extension KeyPath: @retroactive @unchecked Sendable {}

struct ContentView: View {

    @Environment(\.openURL) private var openURL

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
    @State var isShowingSettings: Bool = false

#if os(macOS)
    @State var viewMode: ViewMode = .grid
    @State var sortOrder = [KeyPathComparator(\PixivWork.createDate, order: .reverse)]
    @State var selectedWorkID: FlexibleString?

    enum ViewMode: String {
        case grid, table
    }
#endif

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
#if os(iOS)
        NavigationStack {
            bookmarksView
                .navigationTitle(String(localized: "Bookmarks.Title"))
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        if isLoading {
                            ProgressView()
                        }
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            Task { await refreshBookmarks() }
                        } label: {
                            Label("Shared.Refresh", systemImage: "arrow.clockwise")
                        }
                        .disabled(isLoading)
                    }
                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(.fixed, placement: .topBarTrailing)
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            isShowingSettings = true
                        } label: {
                            Label("Settings.Title", systemImage: "ellipsis")
                        }
                    }
                }
                .sheet(isPresented: $isShowingSettings) {
                    NavigationStack {
                        SettingsView()
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    if #available(iOS 26.0, *) {
                                        Button(role: .confirm) {
                                            isShowingSettings = false
                                        }
                                    } else {
                                        Button(String(localized: "Shared.Done")) {
                                            isShowingSettings = false
                                        }
                                        .fontWeight(.semibold)
                                    }
                                }
                            }
                            .presentationDetents([.medium])
                    }
                }
        }
#else
        NavigationSplitView {
            List {
                NavigationLink {
                    bookmarksView
                } label: {
                    Label("Bookmarks.Title", systemImage: "bookmark.fill")
                }
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Settings.Title", systemImage: "gearshape")
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            bookmarksView
        }
#endif
    }

    var bookmarksView: some View {
        VStack(spacing: 0) {
            if let errorMessage {
#if os(iOS)
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                        .font(.title2)
                    Text(errorMessage)
                    Spacer()
                    Button {
                        self.errorMessage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .tint(.primary)
                            .font(.title2)
                    }
                }
                .padding(12)
                .background(.red.opacity(0.1))
                .clipShape(.rect(cornerRadius: 12))
                .padding(.horizontal, 12)
                .padding(.top, 4)
#else
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(errorMessage)
                    Spacer()
                    Button(String(localized: "Shared.Dismiss")) {
                        self.errorMessage = nil
                    }
                }
                .padding(8)
                .background(.red.opacity(0.1))
#endif
            }

#if os(iOS)
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 100, maximum: 140))],
                    spacing: 8
                ) {
                    ForEach(filteredWorks) { work in
                        BookmarkGridItem(work: work, cookie: sessionCookie)
                    }
                }
                .padding(12)
            }

            if isLoading {
                Divider()
                HStack {
                    ProgressView(value: Double(loadedCount), total: Double(max(total, 1)))
                    Text("Bookmarks.Progress \(loadedCount) \(total)")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
#else
            switch viewMode {
            case .grid:
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 120, maximum: 180))],
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
                    TableColumn(String(localized: "Bookmarks.Table.Title"), value: \.title)
                        .width(min: 150, ideal: 250)
                    TableColumn(String(localized: "Bookmarks.Table.Artist"), value: \.userName)
                        .width(min: 100, ideal: 150)
                    TableColumn(String(localized: "Bookmarks.Table.Pages")) { work in
                        Text("\(work.pageCount)")
                    }
                    .width(50)
                    TableColumn(String(localized: "Bookmarks.Table.Size")) { work in
                        Text("\(work.width)×\(work.height)")
                    }
                    .width(80)
                    TableColumn(String(localized: "Bookmarks.Table.Tags")) { work in
                        Text(work.tags.joined(separator: ", "))
                            .lineLimit(1)
                    }
                    .width(min: 150, ideal: 250)
                    TableColumn(String(localized: "Bookmarks.Table.Date"), value: \.createDate) { work in
                        Text(formattedDate(work.createDate))
                    }
                    .width(min: 100, ideal: 140)
                    TableColumn(String(localized: "Bookmarks.Table.AI")) { work in
                        Text(work.aiType == 2 ? String(localized: "Shared.Yes") : String(localized: "Shared.No"))
                    }
                    .width(40)
                }
                .onChange(of: sortOrder) {
                    works.sort(using: sortOrder)
                }
                .onChange(of: selectedWorkID) {
                    if let id = selectedWorkID {
                        openIllust(id: id.value)
                        selectedWorkID = nil
                    }
                }
            }

            Divider()

            HStack {
                if isLoading {
                    ProgressView(value: Double(loadedCount), total: Double(max(total, 1)))
                        .frame(width: 100)
                    Text("Bookmarks.Progress \(loadedCount) \(total)")
                        .font(.caption)
                        .monospacedDigit()
                } else {
                    Text(debouncedSearchText.isEmpty
                         ? String(localized: "Bookmarks.Count \(works.count)")
                         : String(localized: "Bookmarks.Count.Filtered \(filteredWorks.count) \(works.count)"))
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                Spacer()
            }
            .padding(8)
#endif
        }
        .searchable(text: $searchText, prompt: Text("Bookmarks.Search.Prompt"))
        .onChange(of: searchText) {
            searchDebounceTask?.cancel()
            searchDebounceTask = Task {
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { return }
                debouncedSearchText = searchText
            }
        }
#if os(macOS)
        .navigationTitle(String(localized: "Bookmarks.Title"))
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
                        viewMode == .grid ? String(localized: "Bookmarks.ViewMode.Table") : String(localized: "Bookmarks.ViewMode.Grid"),
                        systemImage: viewMode == .grid ? "list.bullet" : "square.grid.2x2"
                    )
                }
            }
            ToolbarItem {
                Button {
                    Task { await refreshBookmarks() }
                } label: {
                    Label("Shared.Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
#endif
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
            errorMessage = String(localized: "Bookmarks.Error.NotLoggedIn")
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

    func openIllust(id: String) {
        if let url = URL(string: "https://www.pixiv.net/artworks/\(id)") {
            openURL(url)
        }
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
