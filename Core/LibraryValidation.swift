import Foundation

extension LibrarySnapshot {
    /// Validate persisted data as well as imported backups before it reaches SwiftUI/AVPlayer.
    public func validate() throws {
        guard version == 1 else { throw BackupError.version }
        let trackIDs = Set(tracks.map(\.id)), sourceIDs = Set(sources.map(\.id)), routineIDs = Set(routines.map(\.id))
        let s = settings
        guard tracks.count <= 100_000, routines.count <= 100_000,
              trackIDs.count == tracks.count, sourceIDs.count == sources.count,
              routineIDs.count == routines.count,
              sources.allSatisfy({ $0.url.isFileURL }),
              tracks.allSatisfy({ track in
                  track.url.isFileURL && !track.relativePath.hasPrefix("/") &&
                  !track.relativePath.split(separator: "/").contains("..") &&
                  (track.sourceID.map { sourceIDs.contains($0) } ?? true) &&
                  (track.routineID.map { routineIDs.contains($0) } ?? true)
              }),
              routines.allSatisfy({ routine in
                  routine.moves.count <= 100_000 && Set(routine.moves.map(\.id)).count == routine.moves.count &&
                  routine.moves.allSatisfy { $0.time.map { $0.isFinite && (0...31_536_000).contains($0) } ?? true }
              }),
              [0, 3, 5, 10].contains(s.countSeconds), (0...30).contains(s.loopCount),
              s.autoGap.isFinite, (0...86_400).contains(s.autoGap),
              s.textSize.isFinite, (12...48).contains(s.textSize),
              s.sidebarWidth.isFinite, (180...600).contains(s.sidebarWidth),
              s.sideWidth.isFinite, (180...600).contains(s.sideWidth),
              s.videoHeight.isFinite, (120...700).contains(s.videoHeight),
              ["left", "center", "right"].contains(s.alignment)
        else { throw BackupError.invalid }
        if let archive = pendingLegacy {
            guard archive.sequences.values.allSatisfy({ sequence in
                sequence.times.allSatisfy { $0.map { $0.isFinite && (0...31_536_000).contains($0) } ?? true }
            }), Set(archive.routineIDs.values).isSubset(of: routineIDs) else { throw BackupError.invalid }
            if let settings = archive.settings {
                var temporary = LibrarySnapshot(); temporary.settings = settings
                try temporary.validate()
            }
        }
    }
}
