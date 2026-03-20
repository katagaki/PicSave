import SwiftUI

struct SettingsView: View {

    @AppStorage("pixivUserId") var userId: String = ""
    @AppStorage("pixivSessionCookie") var sessionCookie: String = ""

    @State var isShowingLogin: Bool = false

    var isLoggedIn: Bool {
        !userId.isEmpty && !sessionCookie.isEmpty
    }

    var body: some View {
        Form {
            Section("Account") {
                if isLoggedIn {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading) {
                            Text("Logged in")
                                .font(.headline)
                            Text("User ID: \(userId)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Log Out") {
                            userId = ""
                            sessionCookie = ""
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("Not logged in")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Log In with Pixiv") {
                            isShowingLogin = true
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 200)
        .navigationTitle("Settings")
        .sheet(isPresented: $isShowingLogin) {
            PixivLoginView()
        }
    }
}
