import Foundation
import Observation

@MainActor @Observable
final class LibraryStore {
    var data = LibrarySnapshot()
    var notice: String?
    var unavailableSources: Set<UUID> = []
    private let storage: URL
    private var scopes: [URL] = []
    private var rescanning = false
    init(storage: URL? = nil) {
        self.storage = storage ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Seolin/JumpRopePlayer/library.json")
        do {
            if FileManager.default.fileExists(atPath: self.storage.path) {
                let decoded = try JSONDecoder().decode(LibrarySnapshot.self, from: Data(contentsOf: self.storage))
                guard decoded.version == 1 else { throw CocoaError(.fileReadCorruptFile) }
                data = decoded
            }
        } catch { notice = "저장된 라이브러리를 읽지 못했습니다. 원본을 보존했습니다: \(error.localizedDescription)" }
        restoreAccess()
    }
    func save() {
        do {
            try FileManager.default.createDirectory(at: storage.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(data).write(to: storage, options: .atomic)
        } catch { notice = "저장 실패: \(error.localizedDescription)" }
    }
    func access(_ url: URL) {
        guard !scopes.contains(url) else { return }
        if url.startAccessingSecurityScopedResource() { scopes.append(url) }
    }
    func bookmark(_ url: URL) -> Data? {
        #if os(macOS)
        return try? url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil)
        #else
        return try? url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        #endif
    }
    private func resolve(_ value: Data?, fallback: URL) -> URL {
        guard let value else { return fallback }
        var stale = false
        #if os(macOS)
        let options: URL.BookmarkResolutionOptions = [.withSecurityScope, .withoutUI]
        #else
        let options: URL.BookmarkResolutionOptions = [.withoutUI]
        #endif
        return (try? URL(resolvingBookmarkData: value, options: options, relativeTo: nil, bookmarkDataIsStale: &stale)) ?? fallback
    }
    func restoreAccess() {
        unavailableSources.removeAll()
        for index in data.sources.indices {
            let url = resolve(data.sources[index].bookmark, fallback: data.sources[index].url)
            data.sources[index].url = url; access(url)
            if !FileManager.default.isReadableFile(atPath: url.path) { unavailableSources.insert(data.sources[index].id) }
        }
        for index in data.tracks.indices {
            if let sourceID = data.tracks[index].sourceID, let source = data.sources.first(where: { $0.id == sourceID }) {
                data.tracks[index].url = source.url.appendingPathComponent(data.tracks[index].relativePath)
            } else {
                let url = resolve(data.tracks[index].bookmark, fallback: data.tracks[index].url)
                data.tracks[index].url = url; access(url)
            }
            data.tracks[index].missing = !FileManager.default.isReadableFile(atPath: data.tracks[index].url.path)
        }
    }
    func addFiles(_ urls: [URL], source: MediaSource? = nil, explicit: Bool = true) -> [UUID] {
        var ids: [UUID] = []
        for url in urls {
            guard MediaTrack.extensions.contains(url.pathExtension.lowercased()) else { continue }
            if source == nil { access(url) }
            if let index = data.tracks.firstIndex(where: { $0.url.standardizedFileURL == url.standardizedFileURL }) {
                if explicit { data.tracks[index].hidden = false }
                data.tracks[index].missing = false; ids.append(data.tracks[index].id); continue
            }
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            let relative = source.map { String(url.path.dropFirst($0.url.path.count + 1)) }
            var track = MediaTrack(url: url, size: size, bookmark: source == nil ? bookmark(url) : nil, sourceID: source?.id, relativePath: relative)
            if let previous = data.tracks.first(where: { $0.legacyKey == track.legacyKey }) { track.routineID = previous.routineID }
            data.tracks.append(track); ids.append(track.id)
        }
        save(); return ids
    }
    func addFolder(_ url: URL, replacing: UUID? = nil) async {
        access(url)
        if let replacing, let i = data.sources.firstIndex(where: { $0.id == replacing }) {
            data.sources[i].url = url; data.sources[i].bookmark = bookmark(url)
            for j in data.tracks.indices where data.tracks[j].sourceID == replacing {
                data.tracks[j].url = url.appendingPathComponent(data.tracks[j].relativePath)
            }
        } else if !data.sources.contains(where: { $0.url == url }) {
            data.sources.append(MediaSource(url: url, bookmark: bookmark(url)))
        }
        restoreAccess(); await rescan(); save()
    }
    func rescan() async {
        guard !rescanning else { return }; rescanning = true; defer { rescanning = false }
        for source in data.sources {
            guard !unavailableSources.contains(source.id) else { continue }
            let result: [URL]? = await Task.detached {
                var failed = false
                guard let walker = FileManager.default.enumerator(at: source.url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles], errorHandler: { _, _ in failed = true; return false }) else { return nil }
                let urls = walker.compactMap { $0 as? URL }.filter { MediaTrack.extensions.contains($0.pathExtension.lowercased()) && ((try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? false) }
                return failed ? nil : urls
            }.value
            guard let urls = result else { unavailableSources.insert(source.id); continue }
            _ = addFiles(urls, source: source, explicit: false)
            let paths = Set(urls.map(\.path))
            for i in data.tracks.indices where data.tracks[i].sourceID == source.id { data.tracks[i].missing = !paths.contains(data.tracks[i].url.path) }
        }
        save()
    }
    func routine(for track: MediaTrack?) -> Routine {
        guard let id = track?.routineID else { return Routine() }
        return data.routines.first(where: { $0.id == id }) ?? Routine()
    }
    func updateRoutine(_ routine: Routine, trackID: UUID) {
        guard let t = data.tracks.firstIndex(where: { $0.id == trackID }) else { return }
        data.tracks[t].routineID = routine.id
        if let i = data.routines.firstIndex(where: { $0.id == routine.id }) { data.routines[i] = routine } else { data.routines.append(routine) }
        save()
    }
    func deleteRoutine(trackID: UUID) {
        guard let i = data.tracks.firstIndex(where: { $0.id == trackID }) else { return }
        data.tracks[i].routineID = nil; save()
    }
    func link(_ first: UUID, _ second: UUID) {
        guard first != second, let a = data.tracks.first(where: { $0.id == first }), let b = data.tracks.firstIndex(where: { $0.id == second }) else { return }
        guard a.isVideo != data.tracks[b].isVideo else { notice = "음원과 영상 파일을 하나씩 연결해 주세요."; return }
        let routine = routine(for: a); updateRoutine(routine, trackID: first)
        data.tracks[b].routineID = routine.id; save()
        notice = "음원과 영상에 같은 순서표를 연결했습니다."
    }
    func toggleFavorite(_ id: UUID) {
        guard let i = data.tracks.firstIndex(where: { $0.id == id }) else { return }
        data.tracks[i].favorite.toggle()
        data.favorites.removeAll { $0 == id }
        if data.tracks[i].favorite { data.favorites.append(id) }; save()
    }
    func remove(_ id: UUID) { if let i = data.tracks.firstIndex(where: { $0.id == id }) { data.tracks[i].hidden = true; save() } }
    func reconnect(_ id: UUID, to url: URL) {
        guard let i = data.tracks.firstIndex(where: { $0.id == id }) else { return }
        access(url)
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        let replacement = MediaTrack(url: url, size: size, bookmark: bookmark(url))
        data.tracks[i].url = url; data.tracks[i].bookmark = replacement.bookmark
        data.tracks[i].sourceID = nil; data.tracks[i].relativePath = replacement.relativePath
        data.tracks[i].legacyKey = replacement.legacyKey; data.tracks[i].name = replacement.name
        data.tracks[i].isVideo = replacement.isVideo; data.tracks[i].missing = false; save()
    }
    func forgetFolders() {
        data.sources.removeAll()
        for i in data.tracks.indices where data.tracks[i].sourceID != nil {
            data.tracks[i].bookmark = bookmark(data.tracks[i].url); data.tracks[i].sourceID = nil
        }
        unavailableSources.removeAll(); save()
    }
    func orderedTracks(folder: String? = nil, sourceID: UUID? = nil, favorites: Bool = false) -> [MediaTrack] {
        let list = data.tracks.filter { !$0.hidden && !$0.missing && (favorites ? $0.favorite : $0.sourceID == sourceID && $0.folder == (folder ?? "")) }
        let order = favorites ? data.favorites.map(\.uuidString) : (data.orders[orderKey(folder: folder ?? "", source: sourceID)] ?? [])
        return list.sorted { a, b in
            let x = order.firstIndex(of: a.id.uuidString) ?? Int.max, y = order.firstIndex(of: b.id.uuidString) ?? Int.max
            return x == y ? a.name.localizedStandardCompare(b.name) == .orderedAscending : x < y
        }
    }
    func orderKey(folder: String, source: UUID?) -> String { "\(source?.uuidString ?? "files")/\(folder)" }
}
