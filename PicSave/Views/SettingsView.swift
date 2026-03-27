import SwiftUI
import WebKit

struct SettingsView: View {

    @AppStorage("pixivUserId") var userId: String = ""
    @AppStorage("pixivSessionCookie") var sessionCookie: String = ""

    @State var isShowingLogin: Bool = false

    var isLoggedIn: Bool {
        !userId.isEmpty && !sessionCookie.isEmpty
    }

    var body: some View {
        Form {
            Section(String(localized: "Settings.Account")) {
                if isLoggedIn {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Settings.Account.LoggedIn")
                                .font(.headline)
                            Text("Settings.Account.UserID \(userId)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(String(localized: "Settings.Account.LogOut")) {
                            userId = ""
                            sessionCookie = ""
                            let dataStore = WKWebsiteDataStore.default()
                            dataStore.fetchDataRecords(
                                ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()
                            ) { records in
                                let pixivRecords = records.filter {
                                    $0.displayName.contains("pixiv")
                                }
                                dataStore.removeData(
                                    ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                                    for: pixivRecords
                                ) {}
                            }
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("Settings.Account.NotLoggedIn")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(String(localized: "Settings.Account.LogIn")) {
                            isShowingLogin = true
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
#if os(macOS)
        .frame(minWidth: 400, minHeight: 200)
#endif
        .navigationTitle(String(localized: "Settings.Title"))
        .sheet(isPresented: $isShowingLogin) {
#if os(iOS)
            NavigationStack {
                PixivLoginView()
                    .navigationTitle(String(localized: "Login.Title"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            if #available(iOS 26.0, *) {
                                Button(role: .close) {
                                    isShowingLogin = false
                                }
                            } else {
                                Button(String(localized: "Shared.Done")) {
                                    isShowingLogin = false
                                }
                                .fontWeight(.semibold)
                            }
                        }
                    }
            }
#else
            PixivLoginView()
#endif
        }
    }
}
