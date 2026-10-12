// Compile with Core/*.swift, App/LibraryStore.swift and App/PracticeSession.swift.
import Foundation
import AVFoundation
@main struct SmokeTest {
    @MainActor static func main() async throws {
        let storage = URL(fileURLWithPath:"/private/tmp/jrp-smoke-\(UUID().uuidString)/library.json")
        let library = LibraryStore(storage:storage)
        let file = URL(fileURLWithPath:CommandLine.arguments[1])
        let ids = library.addFiles([file]); precondition(ids.count == 1)
        let session = PracticeSession(library:library); session.player.isMuted = true
        session.select(ids[0],play:false)
        for _ in 0..<100 { if !session.loading { break }; try await Task.sleep(for:.milliseconds(50)) }
        precondition(session.duration > 29 && session.duration < 31,"Audio duration failed")
        session.change { $0.title = "검증"; $0.setText("1. 모아뛰기\n2. 이중뛰기\n3. 마무리") }
        library.data.settings.autoGap = 5
        session.seek(1); session.mark(0)
        precondition(session.routine.moves.map(\.time) == [1,6,11])
        session.setTime(0,2); session.undoEdit(); precondition(session.routine.moves[0].time == 1)
        session.resume(); try await Task.sleep(for:.milliseconds(600)); session.pause()
        precondition(session.time > 1.2,"Playback did not advance")
        library.data.settings.loopCount = 0; library.data.settings.loopSound = false
        session.setLoop(TimeRange(start:2,end:3))
        try await Task.sleep(for:.milliseconds(1700))
        precondition(session.time >= 2 && session.time < 3.1,"Loop escaped range")
        session.pause(); session.clearLoop()
        library.toggleFavorite(ids[0]); library.save()
        let restored = LibraryStore(storage:storage)
        precondition(restored.data.tracks[0].favorite)
        precondition(restored.routine(for:restored.data.tracks[0]).moves.map(\.time) == [1,6,11])
        library.remove(ids[0]); precondition(FileManager.default.fileExists(atPath:file.path))
        print("PASS: WAV metadata, playback, sync, undo, loop, persistence, favorite, non-destructive removal")
    }
}
