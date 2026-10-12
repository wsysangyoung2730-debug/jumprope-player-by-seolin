import XCTest
@testable import JumpRopeCore

final class ReleaseSafetyTests: XCTestCase {
    func testBackupRejectsRemoteFilesAndEscapingFolderPaths() throws {
        var snapshot = LibrarySnapshot()
        snapshot.tracks = [MediaTrack(url: URL(string: "https://example.com/song.mp3")!, size: 0)]
        XCTAssertThrowsError(try BackupPayload.decode(JSONEncoder().encode(snapshot)))
        snapshot.tracks = [MediaTrack(url: URL(fileURLWithPath: "/tmp/song.mp3"), size: 0, relativePath: "../song.mp3")]
        XCTAssertThrowsError(try snapshot.validate())
    }
    func testDuplicateMoveIDsAndDanglingReferencesAreRejected() throws {
        var snapshot = LibrarySnapshot()
        let move = Move(name: "모아뛰기", time: 1)
        snapshot.routines = [Routine(moves: [move, move])]
        XCTAssertThrowsError(try snapshot.validate())
        snapshot.routines = []
        var track = MediaTrack(url: URL(fileURLWithPath: "/tmp/song.wav"), size: 0)
        track.routineID = UUID(); snapshot.tracks = [track]
        XCTAssertThrowsError(try snapshot.validate())
    }
    func testExtremeNumbersCannotReachSwiftUIOrIntegerConversion() throws {
        var snapshot = LibrarySnapshot()
        snapshot.settings.textSize = -500
        XCTAssertThrowsError(try snapshot.validate())
        snapshot.settings = PlayerSettings()
        snapshot.routines = [Routine(moves: [Move(name: "동작", time: 1e300)])]
        XCTAssertThrowsError(try snapshot.validate())
        XCTAssertEqual(timeText(1e300), "525600:00")
        XCTAssertEqual(timeText(.infinity), "0:00")
        var routine = Routine(moves: [Move(name: "동작")])
        routine.mark(0, at: .infinity, gap: 1, duration: 10)
        XCTAssertNil(routine.moves[0].time)
    }
    func testTypicalNativeAndLegacyBackupsStillImport() throws {
        var snapshot = LibrarySnapshot()
        let source = MediaSource(url: URL(fileURLWithPath: "/tmp/music"), bookmark: nil)
        let routine = Routine(title: "연습", moves: [Move(name: "모아뛰기", time: 8)])
        var track = MediaTrack(url: source.url.appendingPathComponent("lesson/song.wav"), size: 120,
            sourceID: source.id, relativePath: "lesson/song.wav")
        track.routineID = routine.id
        snapshot.sources = [source]; snapshot.tracks = [track]; snapshot.routines = [routine]
        XCTAssertNoThrow(try BackupPayload.decode(JSONEncoder().encode(snapshot)))
        let raw: [String: Any] = ["jrp:settings": ["autoGap": 1e300, "seqAlign": "invalid"]]
        var archive = try LegacyArchive.parse(JSONSerialization.data(withJSONObject: raw))
        var imported = LibrarySnapshot(); archive.apply(to: &imported)
        XCTAssertEqual(imported.settings.autoGap, 86_400)
        XCTAssertEqual(imported.settings.alignment, "left")
        XCTAssertNoThrow(try imported.validate())
    }
}
