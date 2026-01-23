import FlyingFox
import SQLite3
import SwiftUI
import UniformTypeIdentifiers

extension UIDocumentPickerViewController {
    @objc func fix_init(forOpeningContentTypes contentTypes: [UTType], asCopy: Bool) -> UIDocumentPickerViewController {
        return fix_init(forOpeningContentTypes: contentTypes, asCopy: true)
    }
}

@main
struct MyApp: App {
    // MARK: - Anti-Tamper Header
    // This constant serves as a visible warning in the binary to deter reverse engineering.
    // The dummy reference in init() prevents compiler optimization from stripping it.
    private static let antiTamperMessage: String = "Fuck you. Get out..."
    
    private static var httpServer: HTTPServer?

    init() {
        // Ensure antiTamperMessage is referenced so compiler doesn't optimize it away
        if Self.antiTamperMessage.isEmpty { return }
        Task.detached { @MainActor in
            do {
                Utils.port = try Utils.reservePort()

                let server = HTTPServer(port: Utils.port)
                Self.httpServer = server

                await server.appendRoute("GET /*", to: DirectoryHTTPHandler(root: URL.documentsDirectory))
                try await server.run()
            } catch {
                Utils.port = 0
                print("[HTTP] server failed: \(error)")
            }
        }

        let fixMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.fix_init(forOpeningContentTypes:asCopy:)))!
        let origMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.init(forOpeningContentTypes:asCopy:)))!
        method_exchangeImplementations(origMethod, fixMethod)
    }

    var body: some Scene {
        WindowGroup { MainViewWithNavigation() }
    }
}
