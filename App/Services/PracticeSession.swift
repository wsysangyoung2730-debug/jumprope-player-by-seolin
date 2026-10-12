import AVFoundation
import Observation
import Foundation

@MainActor @Observable
final class PracticeSession {
    let library: LibraryStore
    let player = AVPlayer()
    var selectedID: UUID?
    var fromFavorites = false
    var time: Double = 0
    var duration: Double = 0
    var playing = false
    var loading = false
    var hasVideo = false
    var routine = Routine()
    var editing = false
    var markIndex = 0
    var loopEnabled = false
    var loop: TimeRange?
    var pendingRange: TimeRange?
    var countdown: Int?
    var showEditor = false
    var showSettings = false
    var focus = false
    var videoInStage = false
    var undo: [Routine] = []
    private var observer: Any?
    private var endObserver: NSObjectProtocol?
    private var errorObservation: NSKeyValueObservation?
    private var boundary: Any?
    private var countdownTask: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?
    private var sound: AVAudioPlayer?
    private var audioObservers: [NSObjectProtocol] = []
    private var lastBeep: Int?
    private var previousActive: Int?
    var track: MediaTrack? { library.data.tracks.first { $0.id == selectedID } }
    var active: Int? { routine.active(at: time) }
    var next: Int? { routine.next(at: time) }
    var settings: PlayerSettings { library.data.settings }
    init(library: LibraryStore) {
        self.library = library
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        for name in [AVAudioSession.interruptionNotification, AVAudioSession.routeChangeNotification, AVAudioSession.mediaServicesWereResetNotification] {
            audioObservers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
                let interruption = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
                let route = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
                let shouldPause = name == AVAudioSession.mediaServicesWereResetNotification ||
                    (name == AVAudioSession.interruptionNotification && interruption == AVAudioSession.InterruptionType.began.rawValue) ||
                    (name == AVAudioSession.routeChangeNotification && route == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue)
                if shouldPause { Task { @MainActor in self?.pause() } }
            })
        }
        #endif
        observer = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.03, preferredTimescale: 600), queue: .main) { [weak self] value in
            Task { @MainActor in self?.tick(value.seconds) }
        }
        endObserver = NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: nil, queue: .main) { [weak self] notification in
            guard let item = notification.object as? AVPlayerItem else { return }
            Task { @MainActor in guard let self, item === self.player.currentItem else { return }; self.ended() }
        }
    }
    func select(_ id: UUID, play: Bool = true, favorites: Bool? = nil) {
        guard let item = library.data.tracks.first(where: { $0.id == id }), !item.missing else { library.notice = "원본 파일을 다시 연결해 주세요."; return }
        if let favorites { fromFavorites = favorites }
        if id == selectedID, player.currentItem?.status != .failed, duration > 0 {
            if play { resume() }; return
        }
        pause(); loadTask?.cancel(); clearLoop(); editing = false; undo = []; time = 0; duration = 0
        selectedID = id; routine = library.routine(for: item); markIndex = routine.moves.firstIndex(where: { $0.time == nil }) ?? 0
        loading = true; hasVideo = false
        let asset = AVURLAsset(url: item.url)
        let avItem = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: avItem)
        errorObservation = avItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            if item.status == .failed {
                Task { @MainActor in
                    guard let self, item === self.player.currentItem else { return }
                    self.pause(); self.loading = false; self.duration = 0; self.library.notice = "이 파일을 재생할 수 없습니다. MP3/M4A 또는 H.264·HEVC MP4/MOV로 변환해 주세요. \(item.error?.localizedDescription ?? "")" }
            }
        }
        loadTask = Task { [weak self] in
            do {
                let length = try await asset.load(.duration).seconds
                let playable = try await asset.load(.isPlayable)
                let videoTracks = try await asset.loadTracks(withMediaType:.video)
                guard let self, !Task.isCancelled, self.selectedID == id else { return }
                guard playable, length.isFinite, length > 0 else { throw CocoaError(.fileReadUnknown) }
                self.duration = length; self.hasVideo = !videoTracks.isEmpty; self.loading = false
                if play { self.resume() }
            } catch {
                guard let self, !Task.isCancelled, self.selectedID == id else { return }
                self.pause(); self.loading = false; self.duration = 0; self.library.notice = "재생 형식을 확인해 주세요: \(error.localizedDescription)"
            }
        }
    }
    func toggle() { if playing || countdown != nil { pause() } else { resume() } }
    func resume() {
        guard selectedID != nil, !loading, duration > 0, player.currentItem?.status != .failed else { return }
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { library.notice = "오디오 출력을 시작할 수 없습니다: \(error.localizedDescription)"; return }
        #endif
        if loop != nil { startLoop() } else { if time >= duration && duration > 0 { seek(0) }; player.play(); playing = true }
    }
    func pause() { countdownTask?.cancel(); countdownTask = nil; countdown = nil; player.pause(); playing = false }
    func seek(_ value: Double, play: Bool = false) {
        guard value.isFinite, duration > 0, !loading else { return }
        let value = max(0, min(value, duration))
        time = value; lastBeep = nil
        player.seek(to: CMTime(seconds: value, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        if play { resume() }
    }
    func restart() { guard !loading, duration > 0 else { return }; if loop != nil { startLoop() } else { seek(0, play: true) } }
    var queue: [MediaTrack] {
        guard let track else { return [] }
        return library.orderedTracks(folder: track.folder, sourceID: track.sourceID, favorites: fromFavorites && track.favorite)
    }
    func go(_ delta: Int) {
        guard let selectedID else { return }
        if delta < 0 && time > 3 { seek(0, play: true); return }
        let tracks = queue
        guard !tracks.isEmpty, let i = tracks.firstIndex(where: { $0.id == selectedID }) else { return }
        let next = tracks[(i + delta + tracks.count) % tracks.count]
        if next.id == selectedID { restart() } else { select(next.id) }
    }
    func ended() {
        playing = false
        if loop != nil { startLoop() }
        else if settings.repeatMode == .one { seek(0, play: true) }
        else if settings.repeatMode == .all { go(1) }
    }
    func tick(_ value: Double) {
        guard value.isFinite else { return }; time = max(0, value)
        if playing && player.rate == 0 && player.currentItem?.status == .failed { playing = false }
        if loop != nil && playing && time >= (loop?.end ?? duration) - 0.025 { startLoop(); return }
        if playing, settings.countSound, settings.countSeconds > 0, let next, let target = routine.moves[next].time {
            let remainder = target - time, number = Int(ceil(remainder))
            if remainder > 0 && remainder <= Double(settings.countSeconds), lastBeep != number { beep(); lastBeep = number }
        }
        if previousActive != active {
            if playing && settings.countSound && lastBeep != nil { beep(high: true) }
            previousActive = active; lastBeep = nil
        }
    }
    func beginEditing() { guard selectedID != nil else { return }; showEditor = true; editing = true; markIndex = routine.moves.firstIndex(where: { $0.time == nil }) ?? 0 }
    func change(_ operation: (inout Routine) -> Void, remember: Bool = true) {
        guard let selectedID else { library.notice = "먼저 곡을 선택해 주세요."; return }
        if remember { undo.append(routine) }
        operation(&routine); library.updateRoutine(routine, trackID: selectedID)
    }
    func mark(_ index: Int? = nil) {
        let index = index ?? markIndex
        guard routine.moves.indices.contains(index) else { library.notice = "모든 동작을 기록했습니다."; return }
        change { $0.mark(index, at: time, gap: settings.autoGap, duration: duration) }
        markIndex = index + 1
    }
    func setTime(_ index: Int, _ value: Double?) {
        guard routine.moves.indices.contains(index) else { return }
        guard value.map({ $0.isFinite }) ?? true else { return }
        change { $0.moves[index].time = value.map { (min(duration > 0 ? duration : 31_536_000, max(0, $0)) * 10).rounded() / 10 } }
        markIndex = routine.moves.firstIndex(where: { $0.time == nil }) ?? routine.moves.count
    }
    func undoEdit() { guard let value = undo.popLast(), let selectedID else { return }; routine = value; library.updateRoutine(value, trackID: selectedID); markIndex = routine.moves.firstIndex(where: { $0.time == nil }) ?? 0 }
    func clearTimes() { change { value in for i in value.moves.indices { value.moves[i].time = nil } }; markIndex = 0; editing = true }
    func importText(_ url: URL) {
        do {
            guard let text = TextImport.decode(try library.readImport(url, maximumBytes: 5 * 1024 * 1024)) else { throw CocoaError(.fileReadInapplicableStringEncoding) }
            let value = TextImport.routine(from: text, title: routine.title)
            change { current in current.title = value.title; current.moves = value.moves }; beginEditing()
        } catch { library.notice = "순서표를 읽지 못했습니다: \(error.localizedDescription)" }
    }
    func deleteRoutine(_ id: UUID) { library.deleteRoutine(trackID: id); if id == selectedID { routine = Routine(); undo = []; editing = false } }
    func remove(_ id: UUID) {
        let next = queue.first { $0.id != id }
        library.remove(id)
        if id == selectedID { pause(); if let next { select(next.id, play: false) } else { resetSelection() } }
    }
    func resetSelection() {
        pause(); loadTask?.cancel(); loadTask = nil; errorObservation = nil
        clearLoop(); player.replaceCurrentItem(with: nil)
        selectedID = nil; routine = Routine(); duration = 0; time = 0
        loading = false; hasVideo = false; editing = false; showEditor = false
        undo = []; markIndex = 0; previousActive = nil; lastBeep = nil
    }
    func pick(_ index: Int) {
        guard routine.moves.indices.contains(index) else { return }
        if loopEnabled {
            if let span = routine.span(index, duration: duration) { pickRange(span) }
        } else if let value = routine.moves[index].time { seek(value, play: true) }
        else { library.notice = "이 동작의 싱크를 먼저 기록해 주세요." }
    }
    func step(_ delta: Int) {
        guard !playing, countdown == nil else { return }
        var index = (active ?? -1) + delta
        while routine.moves.indices.contains(index) {
            if let value = routine.moves[index].time { seek(value); return }; index += delta
        }
    }
    func pickRange(_ range: TimeRange) {
        if let start = pendingRange { pendingRange = nil; setLoop(.combining(start, range)) }
        else { pendingRange = range; library.notice = "끝 동작 또는 끝 시간을 선택해 주세요." }
    }
    func setLoop(_ value: TimeRange) {
        let range = TimeRange(start: max(0, value.start), end: min(duration, value.end))
        guard range.isValid else { library.notice = "0.3초 이상의 반복 구간을 선택해 주세요."; return }
        loop = range; loopEnabled = true; installBoundary(); startLoop()
    }
    func adjustLoop(_ value: TimeRange) {
        guard value.end <= duration, value.isValid else { return }; loop = value; installBoundary()
        if playing && (time < value.start || time >= value.end) { startLoop() }
    }
    func installBoundary() {
        if let boundary { player.removeTimeObserver(boundary); self.boundary = nil }
        guard let loop else { return }
        boundary = player.addBoundaryTimeObserver(forTimes: [NSValue(time: CMTime(seconds: loop.end, preferredTimescale: 600))], queue: .main) { [weak self] in
            Task { @MainActor in guard let self, self.playing else { return }; self.startLoop() }
        }
    }
    func clearLoop() { loop = nil; loopEnabled = false; pendingRange = nil; countdownTask?.cancel(); countdownTask = nil; countdown = nil; installBoundary() }
    func toggleLoop() { if loopEnabled { clearLoop() } else if selectedID != nil { loopEnabled = true; library.notice = "순서표에서 시작·끝을 선택하거나 재생 막대를 드래그하세요." } }
    func startLoop() {
        guard let loop, loop.isValid, loop.end <= duration, !loading, player.currentItem?.status != .failed else { return }
        pause(); let id = selectedID
        countdownTask = Task { [weak self] in
            guard let self else { return }
            // Await the precise seek before the countdown so media cannot start at a stale position.
            await self.player.seek(to: CMTime(seconds: loop.start, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
            guard !Task.isCancelled else { return }
            self.time = loop.start
            if self.settings.loopCount > 0 {
                for n in stride(from: self.settings.loopCount, through: 1, by: -1) {
                    guard !Task.isCancelled else { return }; self.countdown = n
                    if self.settings.loopSound { self.beep() }
                    do { try await Task.sleep(for: .seconds(1)) } catch { return }
                }
            }
            guard !Task.isCancelled, self.selectedID == id, self.loop != nil else { return }
            self.countdown = 0
            if self.settings.loopSound { self.beep(high: true) }
            #if os(iOS)
            do { try AVAudioSession.sharedInstance().setActive(true) }
            catch { self.countdown = nil; self.library.notice = "오디오 출력을 시작할 수 없습니다: \(error.localizedDescription)"; return }
            #endif
            self.player.play(); self.playing = true
            do { try await Task.sleep(for: .milliseconds(650)) } catch { return }
            self.countdown = nil; self.countdownTask = nil
        }
    }
    func beep(high: Bool = false) {
        let rate = 44100, count = Int(Double(44100) * (high ? 0.3 : 0.12))
        var pcm = Data()
        for i in 0..<count {
            let envelope = min(1, Double(i)/440) * max(0, 1 - Double(i)/Double(count))
            var sample = Int16(sin(Double(i) * 2 * .pi * (high ? 1320 : 880) / Double(rate)) * 10000 * envelope).littleEndian
            withUnsafeBytes(of: &sample) { pcm.append(contentsOf: $0) }
        }
        var data = Data()
        func text(_ s: String) { data.append(s.data(using: .ascii)!) }
        func number<T: FixedWidthInteger>(_ n: T) { var v = n.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        text("RIFF"); number(UInt32(36 + pcm.count)); text("WAVEfmt "); number(UInt32(16)); number(UInt16(1)); number(UInt16(1)); number(UInt32(rate)); number(UInt32(rate * 2)); number(UInt16(2)); number(UInt16(16)); text("data"); number(UInt32(pcm.count)); data.append(pcm)
        sound = try? AVAudioPlayer(data: data); sound?.play()
    }
}
