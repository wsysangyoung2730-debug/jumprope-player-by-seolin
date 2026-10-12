import SwiftUI

@MainActor @Observable
final class AppActions {
    enum ImportKind { case media, folder, text, link, reconnect(UUID), folderReconnect(UUID), backup }
    var importKind: ImportKind = .media
    var showImporter = false
    var showExporter = false
    var showTutorial = false
    func open(_ kind: ImportKind) { importKind = kind; showImporter = true }
}
