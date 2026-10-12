import XCTest
@testable import JumpRopeCore
final class RoutineTests: XCTestCase {
    func testNumberedReorderPreservesTimingAndIdentity() {
        var r = Routine(moves: [Move(name: "모아뛰기", time: 2), Move(name: "이중뛰기", time: 5)])
        let id = r.moves[1].id
        r.setText("2. 이중뛰기 수정\n1. 모아뛰기\n새 동작")
        XCTAssertEqual(r.moves.map(\.time), [5,2,nil]); XCTAssertEqual(r.moves[0].id,id)
    }
    func testAutoGapStopsAtDurationAndRounds() {
        var r = Routine(moves: (0..<4).map { Move(name: "\($0)") })
        r.mark(0, at: 1.24, gap: 2.5, duration: 7)
        XCTAssertEqual(r.moves.map(\.time), [1.2,3.7,6.2,nil])
    }
    func testUnmarkedMoveUsesNeighborBoundaries() {
        let r = Routine(moves: [Move(name:"a", time:2),Move(name:"b"),Move(name:"c",time:8)])
        XCTAssertEqual(r.span(1,duration:10),TimeRange(start:2,end:8))
        XCTAssertEqual(r.span(2,duration:10),TimeRange(start:8,end:10))
    }
    func testActiveAndNextUseTimeRatherThanRowOrder() {
        let r = Routine(moves:[Move(name:"a",time:10),Move(name:"b",time:2),Move(name:"c")])
        XCTAssertEqual(r.active(at:3),1); XCTAssertEqual(r.next(at:3),0)
        XCTAssertNil(r.active(at:0)); XCTAssertNil(r.next(at:11))
    }
    func testTextImportTitleAndBOM() {
        let text = TextImport.decode(Data("\u{FEFF}음악줄넘기\n1. 모아뛰기\n2. 이중뛰기".utf8))!
        let r = TextImport.routine(from:text)
        XCTAssertEqual(r.title,"음악줄넘기"); XCTAssertEqual(r.moves.map(\.name),["모아뛰기","이중뛰기"])
    }
    func testInvalidLoopRejected() {
        XCTAssertFalse(TimeRange(start:0,end:0.2).isValid)
        XCTAssertFalse(TimeRange(start: .nan,end:10).isValid)
        XCTAssertFalse(TimeRange(start: -1,end:10).isValid)
        XCTAssertTrue(TimeRange(start:0,end:1).isValid)
    }
    func testLibraryRoundTrip() throws {
        var value = LibrarySnapshot(); let r = Routine(title:"테스트",moves:[Move(name:"뛰기",time:1.2)])
        value.routines = [r]; value.settings.loopCount = 5
        let back = try JSONDecoder().decode(LibrarySnapshot.self,from:JSONEncoder().encode(value))
        XCTAssertEqual(back.routines,[r]); XCTAssertEqual(back.settings.loopCount,5)
    }
}
