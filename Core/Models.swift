import Foundation

public struct Move: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID = UUID()
    public var name: String
    public var time: Double?
    public init(id: UUID = UUID(), name: String, time: Double? = nil) { self.id = id; self.name = name; self.time = time }
}
public struct Routine: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var title = ""
    public var moves: [Move] = []
    public init(title: String = "", moves: [Move] = []) { self.title = title; self.moves = moves }
    public var text: String { moves.enumerated().map { "\($0.offset + 1). \($0.element.name)" }.joined(separator: "\n") }
    public var isEmpty: Bool { title.isEmpty && moves.isEmpty }
    public func active(at time: Double) -> Int? {
        moves.indices.filter { moves[$0].time.map { $0 <= time + 0.02 } ?? false }
            .max { (moves[$0].time ?? 0) <= (moves[$1].time ?? 0) }
    }
    public func next(at time: Double) -> Int? {
        moves.indices.filter { moves[$0].time.map { $0 > time + 0.02 } ?? false }
            .min { (moves[$0].time ?? 0) < (moves[$1].time ?? 0) }
    }
    public func span(_ index: Int, duration: Double) -> TimeRange? {
        guard moves.indices.contains(index), duration > 0, duration.isFinite else { return nil }
        let start: Double, end: Double
        if let t = moves[index].time {
            start = t
            end = moves.compactMap(\.time).filter { $0 > t }.min() ?? duration
        } else {
            start = moves.prefix(index).reversed().compactMap(\.time).first ?? 0
            end = moves.dropFirst(index + 1).compactMap(\.time).first ?? duration
        }
        return TimeRange(start: max(0, min(start, duration)), end: min(end, duration))
    }
    public mutating func setText(_ text: String) {
        let old = moves
        var used = Set<Int>()
        let regex = try! NSRegularExpression(pattern: #"^\s*(\d+)\s*[.)\-:번]\s*"#)
        moves = text.components(separatedBy: .newlines).compactMap { raw in
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { return nil }
            let ns = line as NSString
            if let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: ns.length)),
               let n = Int(ns.substring(with: match.range(at: 1))), old.indices.contains(n - 1), !used.contains(n - 1) {
                used.insert(n - 1)
                var move = old[n - 1]; move.name = ns.substring(from: match.range.length)
                return move
            }
            let name = regex.stringByReplacingMatches(in: line, range: NSRange(location: 0, length: ns.length), withTemplate: "")
            return Move(name: name.isEmpty ? line : name)
        }
    }
    public mutating func mark(_ index: Int, at time: Double, gap: Double, duration: Double) {
        guard moves.indices.contains(index) else { return }
        let start = (max(0, time) * 10).rounded() / 10
        moves[index].time = start
        if gap > 0 {
            for i in moves.indices where i > index {
                let value = ((start + Double(i - index) * gap) * 10).rounded() / 10
                if duration > 0 && value > duration { break }
                moves[i].time = value
            }
        }
    }
}
public struct TimeRange: Codable, Equatable, Sendable {
    public var start: Double
    public var end: Double
    public init(start: Double, end: Double) { self.start = start; self.end = end }
    public var isValid: Bool { start.isFinite && end.isFinite && start >= 0 && end - start >= 0.3 }
    public static func combining(_ a: TimeRange, _ b: TimeRange) -> TimeRange {
        TimeRange(start: min(a.start, b.start), end: max(a.end, b.end))
    }
}
public enum RepeatMode: String, Codable, CaseIterable { case off, all, one }
public enum DisplayMode: String, Codable, CaseIterable { case list, rise, video
    public var title: String { switch self { case .list: return "전체 순서표"; case .rise: return "자동 스크롤"; case .video: return "영상" } }
}
public struct PlayerSettings: Codable, Equatable {
    public var countSeconds = 3
    public var countSound = false
    public var loopSound = true
    public var autoGap: Double = 0
    public var loopCount = 3
    public var repeatMode: RepeatMode = .off
    public var stageMode: DisplayMode = .list
    public var sideMode: DisplayMode = .list
    public var textSize: Double = 18
    public var alignment = "left"
    public var sidebarWidth: Double = 260
    public var sideWidth: Double = 310
    public var videoHeight: Double = 320
    public init() {}
}
public struct MediaTrack: Codable, Identifiable, Equatable {
    public var id = UUID()
    public var name: String
    public var url: URL
    public var bookmark: Data?
    public var legacyKey: String
    public var sourceID: UUID?
    public var relativePath: String
    public var isVideo: Bool
    public var routineID: UUID?
    public var favorite = false
    public var hidden = false
    public var missing = false
    public var folder: String { (relativePath as NSString).deletingLastPathComponent }
    public init(url: URL, size: Int, bookmark: Data? = nil, sourceID: UUID? = nil, relativePath: String? = nil) {
        self.url = url; self.name = url.deletingPathExtension().lastPathComponent
        self.bookmark = bookmark; self.sourceID = sourceID
        self.relativePath = relativePath ?? url.lastPathComponent
        self.legacyKey = "jrp:seq:\(url.lastPathComponent)|\(size)"
        self.isVideo = ["mp4", "m4v", "mov", "webm", "mkv"].contains(url.pathExtension.lowercased())
    }
    public static let extensions = Set(["mp3", "m4a", "aac", "wav", "ogg", "oga", "flac", "webm", "mp4", "m4v", "mov", "mkv"])
}
public struct MediaSource: Codable, Identifiable {
    public var id = UUID()
    public var url: URL
    public var bookmark: Data?
    public init(url: URL, bookmark: Data?) { self.url = url; self.bookmark = bookmark }
}
public struct LibrarySnapshot: Codable {
    public var version = 1
    public var tracks: [MediaTrack] = []
    public var sources: [MediaSource] = []
    public var routines: [Routine] = []
    public var favorites: [UUID] = []
    public var orders: [String: [String]] = [:]
    public var settings = PlayerSettings()
    public init() {}
}
public enum TextImport {
    public static func decode(_ data: Data) -> String? {
        if let utf8 = String(data: data, encoding: .utf8) { return utf8.replacingOccurrences(of: "\u{FEFF}", with: "") }
        // CFStringEncoding EUC-KR mapped into NSStringEncoding.
        return String(data: data, encoding: String.Encoding(rawValue: 0x80000940))
    }
    public static func routine(from text: String, title: String = "") -> Routine {
        var lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        var result = Routine(title: title)
        if lines.count > 1, lines[0].first?.isNumber != true { result.title = lines.removeFirst() }
        result.setText(lines.joined(separator: "\n"))
        return result
    }
}
