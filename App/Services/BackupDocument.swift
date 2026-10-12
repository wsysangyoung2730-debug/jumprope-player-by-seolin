import SwiftUI
import UniformTypeIdentifiers

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    private var snapshot: LibrarySnapshot?
    private var importedData: Data?
    init(snapshot: LibrarySnapshot) { self.snapshot = snapshot }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw BackupError.invalid }
        importedData = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        if let snapshot {
            try snapshot.validate()
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return FileWrapper(regularFileWithContents: try encoder.encode(snapshot))
        }
        guard let importedData else { throw BackupError.invalid }
        return FileWrapper(regularFileWithContents: importedData)
    }
}
