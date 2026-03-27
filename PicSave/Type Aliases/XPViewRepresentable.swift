#if os(iOS)
import SwiftUI
typealias XPViewRepresentable = UIViewRepresentable
#elseif os(macOS)
import SwiftUI
typealias XPViewRepresentable = NSViewRepresentable
#endif
