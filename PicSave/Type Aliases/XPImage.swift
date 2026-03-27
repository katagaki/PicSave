#if os(iOS)
import UIKit
typealias XPImage = UIImage
#elseif os(macOS)
import AppKit
typealias XPImage = NSImage
#endif
