import Foundation

public struct LegacySequence: Codable {
    public var title: String
    public var text: String
    public var times: [Double?]
    public var link: String?
    public var savedAt: Double?
}
public struct LegacyArchive: Codable {
    public var sequences: [String: LegacySequence]
    public var favorites: [String]
    public var orders: [String: [String]]
    public var settings: PlayerSettings?
    public var routineIDs: [String: UUID] = [:]
    public static func parse(_ data: Data) throws -> LegacyArchive {
        guard let root = try JSONSerialization.jsonObject(with:data) as? [String:Any] else { throw BackupError.invalid }
        let raw = root["entries"] as? [String:Any] ?? root
        guard raw.keys.contains(where:{ $0.hasPrefix("jrp:") }) else { throw BackupError.invalid }
        func value(_ key:String) -> Any? {
            guard let entry = raw[key] else { return nil }
            if let string = entry as? String, let bytes = string.data(using:.utf8) { return try? JSONSerialization.jsonObject(with:bytes,options:.fragmentsAllowed) }
            return entry
        }
        var sequences: [String:LegacySequence] = [:], orders: [String:[String]] = [:]
        for key in raw.keys {
            if key.hasPrefix("jrp:seq:"), let object = value(key) as? [String:Any] {
                let times = (object["times"] as? [Any] ?? []).map { v -> Double? in guard let number = v as? Double, number.isFinite, number >= 0 else { return nil }; return number }
                sequences[key] = LegacySequence(title:object["title"] as? String ?? "",text:object["text"] as? String ?? "",times:times,link:object["link"] as? String,savedAt:object["savedAt"] as? Double)
            } else if key.hasPrefix("jrp:order:"), let order = value(key) as? [String] { orders[String(key.dropFirst(10))] = order }
        }
        var settings: PlayerSettings?
        if let values = value("jrp:settings") as? [String:Any] {
            var s = PlayerSettings()
            if let n = values["countSec"] as? Int { s.countSeconds = [0,3,5,10].contains(n) ? n : 3 }
            s.countSound = (values["countSound"] as? Int ?? 0) != 0
            s.autoGap = max(0,values["autoGap"] as? Double ?? 0)
            s.loopCount = min(30,max(0,values["loopCount"] as? Int ?? 3))
            s.repeatMode = RepeatMode(rawValue:values["repeat"] as? String ?? "off") ?? .off
            func mode(_ v:Any?) -> DisplayMode { switch v as? String { case "vid": return .video; case "rise": return .rise; default: return .list } }
            s.stageMode = mode(values["viewMode"]); s.sideMode = mode(values["sideView"])
            s.textSize = min(48,max(12,(values["seqFz"] as? Double ?? 1.1)*16))
            s.alignment = values["seqAlign"] as? String ?? "left"
            if let w = values["sideW"] as? Double, w > 0 { s.sideWidth = min(400,max(200,w)) }
            if let w = values["listW"] as? Double, w > 0 { s.sidebarWidth = min(440,max(210,w)) }
            settings = s
        }
        return LegacyArchive(sequences:sequences,favorites:value("jrp:favs") as? [String] ?? [],orders:orders,settings:settings)
    }
    public mutating func apply(to snapshot: inout LibrarySnapshot) {
        if let settings { snapshot.settings = settings; self.settings = nil }
        for key in sequences.keys.sorted() {
            guard let value = sequences[key] else { continue }
            let matches = snapshot.tracks.indices.filter { snapshot.tracks[$0].legacyKey == key }
            guard !matches.isEmpty else { continue }
            let partner = value.link.flatMap { sequences[$0] }
            let chosen = (partner?.savedAt ?? 0) > (value.savedAt ?? 0) ? partner! : value
            var routine = Routine(title:chosen.title); routine.setText(chosen.text)
            for i in routine.moves.indices { if chosen.times.indices.contains(i) { routine.moves[i].time = chosen.times[i] } }
            if let id = routineIDs[key] ?? value.link.flatMap({ routineIDs[$0] }) { routine.id = id }
            else { snapshot.routines.append(routine) }
            routineIDs[key] = routine.id
            if let link = value.link { routineIDs[link] = routine.id }
            for i in matches { snapshot.tracks[i].routineID = routine.id }
            sequences.removeValue(forKey:key)
        }
        var remaining: [String] = []
        for key in favorites {
            let ids = snapshot.tracks.indices.filter { snapshot.tracks[$0].legacyKey == key }
            if ids.isEmpty { remaining.append(key) }
            for i in ids {
                snapshot.tracks[i].favorite = true
                if !snapshot.favorites.contains(snapshot.tracks[i].id) { snapshot.favorites.append(snapshot.tracks[i].id) }
            }
        }
        favorites = remaining
        for path in orders.keys.sorted() {
            let nativeKey: String
            if path.isEmpty { nativeKey = "files/" }
            else {
                guard let source = snapshot.sources.first(where:{ path == $0.url.lastPathComponent || path.hasPrefix($0.url.lastPathComponent+"/") }) else { continue }
                let folder = path == source.url.lastPathComponent ? "" : String(path.dropFirst(source.url.lastPathComponent.count+1))
                nativeKey = "\(source.id.uuidString)/\(folder)"
            }
            let translated = (orders[path] ?? []).compactMap { id -> String? in
                if id.hasPrefix("d:") {
                    let name = String(id.dropFirst(2))
                    if path.isEmpty, let source = snapshot.sources.first(where:{ $0.url.lastPathComponent == name }) { return "source:\(source.id)" }
                    let folder = String(nativeKey.dropFirst(nativeKey.firstIndex(of:"/").map { nativeKey.distance(from:nativeKey.startIndex,to:$0)+1 } ?? 0))
                    return "folder:\(folder.isEmpty ? name : folder+"/"+name)"
                }
                if id.hasPrefix("f:") {
                    let fullPath = String(id.dropFirst(2))
                    return snapshot.tracks.first { track in
                        let prefix = snapshot.sources.first(where:{ $0.id == track.sourceID }).map { $0.url.lastPathComponent+"/" } ?? ""
                        return prefix+track.relativePath == fullPath
                    }?.id.uuidString
                }
                return nil
            }
            if !translated.isEmpty { snapshot.orders[nativeKey] = translated; orders.removeValue(forKey:path) }
        }
    }
}
public enum BackupError: LocalizedError {
    case invalid, version
    public var errorDescription: String? { self == .version ? "지원하지 않는 백업 버전입니다." : "올바른 줄넘기 플레이어 백업이 아닙니다." }
}
public enum BackupPayload {
    case native(LibrarySnapshot), legacy(LegacyArchive)
    public static func decode(_ data: Data) throws -> BackupPayload {
        if let object = try JSONSerialization.jsonObject(with:data) as? [String:Any], object["tracks"] != nil {
            let snapshot = try JSONDecoder().decode(LibrarySnapshot.self,from:data)
            guard snapshot.version == 1 else { throw BackupError.version }
            guard Set(snapshot.tracks.map(\.id)).count == snapshot.tracks.count,
                  Set(snapshot.routines.map(\.id)).count == snapshot.routines.count,
                  snapshot.settings.autoGap.isFinite,
                  (0...30).contains(snapshot.settings.loopCount),
                  snapshot.routines.allSatisfy({ $0.moves.allSatisfy { $0.time.map { $0.isFinite && $0 >= 0 } ?? true } }) else { throw BackupError.invalid }
            return .native(snapshot)
        }
        return .legacy(try LegacyArchive.parse(data))
    }
}
