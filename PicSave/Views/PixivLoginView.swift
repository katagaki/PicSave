import SwiftUI
import WebKit

struct PixivLoginView: View {

    @AppStorage("pixivUserId") var userId: String = ""
    @AppStorage("pixivSessionCookie") var sessionCookie: String = ""

    @Environment(\.dismiss) var dismiss

    @State var isLoggingIn: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            if isLoggingIn {
                PixivWebView(onLoginComplete: handleLoginComplete)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("Logged in successfully!")
                        .font(.headline)
                    Text("User ID: \(userId)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 480, minHeight: 600)
    }

    func handleLoginComplete(cookies: [HTTPCookie]) {
        let cookieString = cookies
            .map { "\($0.name)=\($0.value)" }
            .joined(separator: "; ")
        sessionCookie = cookieString

        if let phpSession = cookies.first(where: { $0.name == "PHPSESSID" }) {
            let sessionValue = phpSession.value
            let components = sessionValue.split(separator: "_")
            if let extractedUserId = components.first {
                userId = String(extractedUserId)
            }
        }

        isLoggingIn = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }
}

struct PixivWebView: NSViewRepresentable {

    let loginURL = URL(string: "https://accounts.pixiv.net/login?return_to=https%3A%2F%2Fwww.pixiv.net%2F")!
    let successHost = "www.pixiv.net"
    var onLoginComplete: ([HTTPCookie]) -> Void

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: loginURL))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(successHost: successHost, onLoginComplete: onLoginComplete)
    }

    class Coordinator: NSObject, WKNavigationDelegate {

        let successHost: String
        let onLoginComplete: ([HTTPCookie]) -> Void
        var hasCompleted = false

        init(successHost: String, onLoginComplete: @escaping ([HTTPCookie]) -> Void) {
            self.successHost = successHost
            self.onLoginComplete = onLoginComplete
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard !hasCompleted,
                  let url = webView.url,
                  url.host == successHost else {
                return
            }
            hasCompleted = true

            let dataStore = webView.configuration.websiteDataStore
            dataStore.httpCookieStore.getAllCookies { [weak self] cookies in
                let pixivCookies = cookies.filter { cookie in
                    cookie.domain.contains("pixiv.net")
                }
                DispatchQueue.main.async {
                    self?.onLoginComplete(pixivCookies)
                }
            }
        }
    }
}
