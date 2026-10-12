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
    private var saveDisabled = false
    private var revision = UUID()
    private var lastSaved: Data?
    init(storage: URL? = nil) {
        self.storage = storage ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Seolin/JumpRopePlayer/library.json")
        do {
            if FileManager.default.fileExists(atPath: self.storage.path) {
                let decoded = try JSONDecoder().decode(LibrarySnapshot.self, from: Data(contentsOf: self.storage))
                try decoded.validate()
                data = decoded
            }
        } catch {
            let recovery = self.storage.deletingLastPathComponent().appendingPathComponent("unreadable-\(UUID().uuidString).json")
            do { try FileManager.default.copyItem(at:self.storage,to:recovery); notice = "저장 데이터를 읽지 못해 복구용 사본을 보관했습니다." }
            catch { saveDisabled = true; notice = "저장 데이터를 읽지 못했습니다: \(error.localizedDescription)" }
        }
        restoreAccess()
    }
    func save() {
        guard !saveDisabled else { return }
        do {
            try data.validate()
            try FileManager.default.createDirectory(at: storage.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let bytes = try encoder.encode(data)
            guard bytes != lastSaved else { return }
            try bytes.write(to: storage, options: .atomic)
            lastSaved = bytes
        } catch { notice = "저장 실패: \(error.localizedDescription)" }
    }
    func access(_ url: URL) {
        guard url.isFileURL, !scopes.contains(url) else { return }
        if url.startAccessingSecurityScopedResource() { scopes.append(url) }
    }
    func readImport(_ url: URL, maximumBytes: Int = 100 * 1024 * 1024) throws -> Data {
        guard url.isFileURL else { throw BackupError.invalid }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size <= maximumBytes else { throw BackupError.invalid }
        let bytes = try Data(contentsOf: url, options: .mappedIfSafe)
        guard bytes.count <= maximumBytes else { throw BackupError.invalid }
        return bytes
    }
    func bookmark(_ url: URL) -> Data? {
        #if os(macOS)
        return try? url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil)
        #else
        return try? url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        #endif
    }
    private func resolve(_ value: inout Data?, fallback: URL) -> URL {
        guard let saved = value else { return fallback }
        var stale = false
        #if os(macOS)
        let options: URL.BookmarkResolutionOptions = [.withSecurityScope, .withoutUI]
        #else
        let options: URL.BookmarkResolutionOptions = [.withoutUI]
        #endif
        guard let url = try? URL(resolvingBookmarkData: saved, options: options, relativeTo: nil, bookmarkDataIsStale: &stale) else { return fallback }
        access(url)
        if stale, let refreshed = bookmark(url) { value = refreshed }
        return url
    }
    func restoreAccess() {
        unavailableSources.removeAll()
        for index in data.sources.indices {
            var saved = data.sources[index].bookmark
            let url = resolve(&saved, fallback: data.sources[index].url)
            data.sources[index].bookmark = saved
            data.sources[index].url = url; access(url)
            if !FileManager.default.isReadableFile(atPath: url.path) { unavailableSources.insert(data.sources[index].id) }
        }
        for index in data.tracks.indices {
            if let sourceID = data.tracks[index].sourceID, let source = data.sources.first(where: { $0.id == sourceID }) {
                data.tracks[index].url = source.url.appendingPathComponent(data.tracks[index].relativePath)
            } else {
                var saved = data.tracks[index].bookmark
                let url = resolve(&saved, fallback: data.tracks[index].url)
                data.tracks[index].bookmark = saved
                data.tracks[index].url = url; access(url)
            }
            data.tracks[index].missing = !FileManager.default.isReadableFile(atPath: data.tracks[index].url.path)
        }
    }
    func addFiles(_ urls: [URL], source: MediaSource? = nil, explicit: Bool = true, persist: Bool = true) -> [UUID] {
        var ids: [UUID] = []
        for url in urls {
            guard url.isFileURL, MediaTrack.extensions.contains(url.pathExtension.lowercased()) else { continue }
            if source == nil { access(url) }
            guard FileManager.default.isReadableFile(atPath: url.path) else { continue }
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
        applyLegacy(); if persist { save() }; return ids
    }
    func addFolder(_ url: URL, replacing: UUID? = nil) async {
        guard url.isFileURL else { return }
        revision = UUID()
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
    func rescan(preserving: UUID? = nil) async {
        guard !rescanning else { return }; rescanning = true; defer { rescanning = false }
        let expectedRevision = revision
        for source in data.sources {
            guard !unavailableSources.contains(source.id) else { continue }
            let result: [URL]? = await Task.detached {
                var failed = false
                guard let walker = FileManager.default.enumerator(at: source.url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles], errorHandler: { _, _ in failed = true; return false }) else { return nil }
                let urls = walker.compactMap { $0 as? URL }.filter { MediaTrack.extensions.contains($0.pathExtension.lowercased()) && ((try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? false) }
                return failed ? nil : urls
            }.value
            guard revision == expectedRevision, !Task.isCancelled else { return }
            guard let urls = result else { unavailableSources.insert(source.id); continue }
            _ = addFiles(urls, source: source, explicit: false, persist: false)
            let paths = Set(urls.map(\.path))
            for i in data.tracks.indices where data.tracks[i].sourceID == source.id && data.tracks[i].id != preserving { data.tracks[i].missing = !paths.contains(data.tracks[i].url.path) }
        }
        save()
    }
    func applyLegacy() {
        guard var archive = data.pendingLegacy else { return }
        data.pendingLegacy = nil
        archive.apply(to:&data)
        data.pendingLegacy = archive
    }
    func restore(_ payload: BackupPayload) throws {
        if FileManager.default.fileExists(atPath:storage.path) {
            let copy = storage.deletingLastPathComponent().appendingPathComponent("before-import-\(Int(Date().timeIntervalSince1970))-\(UUID().uuidString.prefix(4)).json")
            try FileManager.default.copyItem(at:storage,to:copy)
        }
        revision = UUID()
        saveDisabled = false
        lastSaved = nil
        switch payload {
        case .native(let snapshot):
            try snapshot.validate()
            for url in scopes { url.stopAccessingSecurityScopedResource() }; scopes.removeAll()
            data = snapshot; restoreAccess()
        case .legacy(let archive): data.pendingLegacy = archive; applyLegacy()
        }
        save()
        let pending = data.pendingLegacy?.sequences.count ?? 0
        notice = pending > 0 ? "가져왔습니다. 원본 파일을 추가하면 남은 순서표 \(pending)개가 자동 연결됩니다." : "백업을 가져왔습니다. 필요한 파일·폴더는 다시 연결해 주세요."
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
        guard url.isFileURL, MediaTrack.extensions.contains(url.pathExtension.lowercased()),
              let i = data.tracks.firstIndex(where: { $0.id == id }) else { notice = "지원하는 로컬 음원·영상을 선택해 주세요."; return }
        access(url)
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        let replacement = MediaTrack(url: url, size: size, bookmark: bookmark(url))
        data.tracks[i].url = url; data.tracks[i].bookmark = replacement.bookmark
        data.tracks[i].sourceID = nil; data.tracks[i].relativePath = replacement.relativePath
        data.tracks[i].legacyKey = replacement.legacyKey; data.tracks[i].name = replacement.name
        data.tracks[i].isVideo = replacement.isVideo; data.tracks[i].missing = false; save()
    }
    func forgetFolders() {
        revision = UUID()
        data.sources.removeAll()
        for i in data.tracks.indices where data.tracks[i].sourceID != nil {
            data.tracks[i].bookmark = bookmark(data.tracks[i].url); data.tracks[i].sourceID = nil
            data.tracks[i].relativePath = data.tracks[i].url.lastPathComponent
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
