import SwiftUI
import UniformTypeIdentifiers
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(snapshot:LibrarySnapshot) { let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted,.sortedKeys]; data = (try? encoder.encode(snapshot)) ?? Data() }
    init(configuration:ReadConfiguration) throws { guard let data = configuration.file.regularFileContents else { throw BackupError.invalid }; self.data = data }
    func fileWrapper(configuration:WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents:data) }
}
