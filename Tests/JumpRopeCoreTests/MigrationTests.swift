import XCTest
@testable import JumpRopeCore
final class MigrationTests: XCTestCase {
    private func archive() throws -> LegacyArchive {
        let object: [String:Any] = ["entries":[
            "jrp:seq:song.wav|100":["title":"음악줄넘기","text":"1. 모아뛰기\n2. 이중뛰기","times":[1.2,4.5],"link":"jrp:seq:video.mp4|200"],
            "jrp:seq:video.mp4|200":["title":"음악줄넘기","text":"1. 모아뛰기\n2. 이중뛰기","times":[1.2,4.5],"link":"jrp:seq:song.wav|100"],
            "jrp:favs":["jrp:seq:song.wav|100"],
            "jrp:settings":["countSec":5,"loopCount":10,"repeat":"all"]]]
        return try LegacyArchive.parse(JSONSerialization.data(withJSONObject:object))
    }
    func testPendingSequencesSurviveUntilFilesAdded() throws {
        var archive = try archive(), snapshot = LibrarySnapshot()
        archive.apply(to:&snapshot)
        XCTAssertEqual(archive.sequences.count,2)
        snapshot.tracks.append(MediaTrack(url:URL(fileURLWithPath:"/tmp/song.wav"),size:100))
        archive.apply(to:&snapshot)
        XCTAssertEqual(archive.sequences.count,1)
        XCTAssertEqual(snapshot.routines[0].moves.map(\.time),[1.2,4.5])
        XCTAssertTrue(snapshot.tracks[0].favorite)
        XCTAssertEqual(snapshot.settings.countSeconds,5)
    }
    func testLinkedFileAddedLaterSharesEditedRoutine() throws {
        var archive = try archive(), snapshot = LibrarySnapshot()
        snapshot.tracks.append(MediaTrack(url:URL(fileURLWithPath:"/tmp/song.wav"),size:100))
        archive.apply(to:&snapshot)
        snapshot.routines[0].moves[0].time = 8
        snapshot.tracks.append(MediaTrack(url:URL(fileURLWithPath:"/tmp/video.mp4"),size:200))
        archive.apply(to:&snapshot)
        XCTAssertEqual(snapshot.tracks[0].routineID,snapshot.tracks[1].routineID)
        XCTAssertEqual(snapshot.routines.count,1)
        XCTAssertEqual(snapshot.routines[0].moves[0].time,8)
    }
    func testRejectsUnrelatedJSONAndFutureVersion() throws {
        XCTAssertThrowsError(try BackupPayload.decode(Data("{\"unrelated\":1}".utf8)))
        var value = LibrarySnapshot(); value.version = 99
        XCTAssertThrowsError(try BackupPayload.decode(JSONEncoder().encode(value)))
    }
    func testLegacyStringValuesAndMissingTime() throws {
        let raw: [String:String] = ["jrp:seq:song.wav|100":"{\"text\":\"1. 모아뛰기\",\"times\":[null]}"]
        let archive = try LegacyArchive.parse(JSONSerialization.data(withJSONObject:raw))
        XCTAssertNil(archive.sequences.values.first?.times[0])
    }
    func testEUCKR() {
        XCTAssertEqual(TextImport.decode(Data([0xBE,0xC8,0xB3,0xE7])),"안녕")
    }
}
