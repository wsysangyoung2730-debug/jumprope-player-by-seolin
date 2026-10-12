#if DEBUG
import SwiftUI
import AVFoundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Captures the real app views with isolated, fictitious local practice data.
/// Entirely excluded from Release; never changes the user's library or media.
@MainActor enum StoreCapture {
    private static var started = false
    static var enabled: Bool { CommandLine.arguments.contains("--store-capture") }
    static var page: Int {
        guard let index = CommandLine.arguments.firstIndex(of: "--store-page"), CommandLine.arguments.indices.contains(index + 1)
        else { return 1 }
        return Int(CommandLine.arguments[index + 1]) ?? 1
    }
    static func library() -> LibraryStore {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("store-fixture-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let library = LibraryStore(storage: folder.appendingPathComponent("library.json"))
        let names = ["01. 리듬 점프 · 기본 연습", "02. 함께 뛰기 · 연결 동작", "03. 스텝 업 · 도전 루틴", "04. 가볍게 · 마무리"]
        for (index, name) in names.enumerated() {
            let url = folder.appendingPathComponent(name).appendingPathExtension("wav")
            try! wave().write(to: url)
            let id = library.addFiles([url])[0]
            let routine = Routine(title: index == 0 ? "리듬 점프 · 기본 8동작" : name,
                moves: ["모아뛰기", "번갈아 뛰기", "가위바위보", "옆 흔들어 뛰기", "앞뒤 뛰기", "교차 뛰기", "이중뛰기", "가볍게 마무리"].enumerated().map { Move(name: $0.element, time: Double($0.offset * 8)) })
            library.updateRoutine(routine, trackID: id)
            if index < 2 { library.toggleFavorite(id) }
        }
        library.data.settings.sideMode = .rise
        library.data.settings.loopSound = false
        library.data.settings.countSound = false
        return library
    }
    private static func wave() -> Data {
        let rate = 8000, pcm = Data(repeating: 0, count: 8000 * 2 * 72)
        var data = Data()
        func text(_ value: String) { data.append(Data(value.utf8)) }
        func number<T: FixedWidthInteger>(_ number: T) {
            var value = number.littleEndian; withUnsafeBytes(of: &value) { data.append(contentsOf: $0) }
        }
        text("RIFF"); number(UInt32(36 + pcm.count)); text("WAVEfmt "); number(UInt32(16))
        number(UInt16(1)); number(UInt16(1)); number(UInt32(rate)); number(UInt32(rate * 2))
        number(UInt16(2)); number(UInt16(16)); text("data"); number(UInt32(pcm.count)); data.append(pcm)
        return data
    }
    static func run(session: PracticeSession, actions: AppActions) async {
        guard enabled, !started else { return }
        started = true
        do {
            try await Task.sleep(for: .seconds(1))
            #if os(macOS)
            for _ in 0..<100 {
                if NSApp.windows.contains(where: { $0.canBecomeMain && $0.contentView != nil }) { break }
                try await Task.sleep(for: .milliseconds(200))
            }
            guard let window = NSApp.windows.first(where: { $0.canBecomeMain && $0.contentView != nil }) else { throw CocoaError(.coderReadCorrupt) }
            window.setContentSize(NSSize(width: 1420, height: 840))
            window.appearance = NSAppearance(named: .aqua)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            #else
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            scene.windows.first?.overrideUserInterfaceStyle = .light
            #endif
            for _ in 0..<600 {
                if !session.loading && session.duration > 0 { break }
                try await Task.sleep(for: .milliseconds(50))
            }
            guard session.duration > 0 else { throw CocoaError(.fileReadUnknown) }
            session.player.isMuted = true
            let pages = page == 0 ? Array(1...5) : [page]
            for page in pages {
            actions.showTutorial = false
            session.pause(); session.clearLoop(); session.showEditor = false; session.editing = false; session.focus = false
            session.library.data.settings.stageMode = .list
            session.library.data.settings.countSeconds = 3
            try await Task.sleep(for: .milliseconds(700))
            session.seek(18)
            switch page {
            case 2: session.beginEditing()
            case 3:
                session.library.data.settings.loopCount = 0
                session.setLoop(TimeRange(start: 16, end: 40))
                try await Task.sleep(for: .milliseconds(500))
                session.pause(); session.seek(26)
            case 4:
                session.library.data.settings.stageMode = .rise
                session.library.data.settings.countSeconds = 5
                session.focus = true
                session.seek(27)
            case 5: actions.showTutorial = true
            default: break
            }
            try await Task.sleep(for: .seconds(2))
            let output = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("StoreCaptures")
            try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
            #if os(macOS)
            // The app's own window, including its native toolbar and any attached sheet.
            let target = window.attachedSheet ?? window
            guard let view = target.contentView?.superview,
                  let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
            view.cacheDisplay(in: view.bounds, to: bitmap)
            guard let bytes = bitmap.representation(using: .png, properties: [:]) else { return }
            try bytes.write(to: output.appendingPathComponent("mac-\(page).png"))
            print("STORE_CAPTURE \(output.path)/mac-\(page).png")
            #else
            guard let window = scene.windows.first(where: { $0.isKeyWindow }) else { return }
            let format = UIGraphicsImageRendererFormat(); format.scale = 2; format.opaque = true
            let renderer = UIGraphicsImageRenderer(bounds: window.bounds, format: format)
            let bytes = renderer.pngData { _ in window.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
            try bytes.write(to: output.appendingPathComponent("ipad-\(page).png"))
            print("STORE_CAPTURE \(output.path)/ipad-\(page).png")
            #endif
            }
            #if os(macOS)
            actions.showTutorial = false
            try await Task.sleep(for: .milliseconds(400))
            NSApp.terminate(nil)
            #endif
        } catch {
            FileHandle.standardError.write(Data("STORE_CAPTURE_ERROR \(error)\n".utf8))
            #if os(macOS)
            NSApp.terminate(nil)
            #endif
        }
    }
}
#endif
