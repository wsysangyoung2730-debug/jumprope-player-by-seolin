#if DEBUG
import Foundation
@MainActor enum QASeed {
    static func library() -> LibraryStore {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("jumprope-qa-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        let url = folder.appendingPathComponent("QA 음악줄넘기.wav")
        let pcm = Data(repeating:0,count:44100*2*30)
        var data = Data()
        func text(_ s:String) { data.append(Data(s.utf8)) }
        func number<T:FixedWidthInteger>(_ n:T) { var v = n.littleEndian; withUnsafeBytes(of:&v) { data.append(contentsOf:$0) } }
        text("RIFF");number(UInt32(36+pcm.count));text("WAVEfmt ");number(UInt32(16));number(UInt16(1));number(UInt16(1));number(UInt32(44100));number(UInt32(88200));number(UInt16(2));number(UInt16(16));text("data");number(UInt32(pcm.count));data.append(pcm)
        try? data.write(to:url)
        let library = LibraryStore(storage:folder.appendingPathComponent("library.json"))
        if let id = library.addFiles([url]).first {
            let routine = Routine(title:"음악줄넘기 1단계",moves:[Move(name:"모아뛰기",time:0),Move(name:"번갈아 뛰기",time:6),Move(name:"가위바위보",time:12),Move(name:"이중뛰기",time:18),Move(name:"마무리",time:24)])
            library.updateRoutine(routine,trackID:id); library.toggleFavorite(id)
        }
        library.data.settings.sideMode = .rise; library.data.settings.loopSound = false
        return library
    }
}
#endif
