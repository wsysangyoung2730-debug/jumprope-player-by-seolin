import SwiftUI
import UniformTypeIdentifiers

struct RootView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(PracticeSession.self) private var session
    @Environment(AppActions.self) private var actions
    @Environment(\.scenePhase) private var scenePhase
    @State private var visibility: NavigationSplitViewVisibility = .all
    @State private var deleteID: UUID?
    var body: some View {
        @Bindable var session = session
        @Bindable var actions = actions
        NavigationSplitView(columnVisibility: $visibility) {
            LibraryView(deleteID: $deleteID)
                .navigationSplitViewColumnWidth(min: 210, ideal: library.data.settings.sidebarWidth, max: 440)
                .onGeometryChange(for: Double.self) { $0.size.width } action: { if $0 >= 210 { library.data.settings.sidebarWidth = $0 } }
        } detail: {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    workspace(wide: geometry.size.width > 900)
                    Divider()
                    TransportView()
                }
            }
            .navigationTitle(session.track?.name ?? "JUMPROPE PLAYER")
            .toolbar {
                ToolbarItemGroup {
                    Button { session.beginEditing() } label: { Label("순서표 편집", systemImage: "list.bullet.clipboard") }.disabled(session.selectedID == nil)
                    Button { actions.open(.link) } label: { Label("음원·영상 연결", systemImage: "link") }.disabled(session.selectedID == nil)
                    Button { session.focus.toggle() } label: { Label("집중 보기", systemImage: session.focus ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right") }
                    Button { session.showSettings = true } label: { Label("설정", systemImage: "slider.horizontal.3") }
                }
            }
        }
        .tint(.blue)
        .onChange(of: session.focus) { _, value in visibility = value ? .detailOnly : .all }
        .sheet(isPresented: $session.showSettings) { SettingsView().frame(minWidth: 360, idealWidth: 520, minHeight: 540) }
        #if os(iOS)
        .sheet(isPresented: $session.showEditor, onDismiss: { session.editing = false }) { EditorView().presentationDetents([.large]) }
        #endif
        .fileImporter(isPresented: $actions.showImporter, allowedContentTypes: importTypes, allowsMultipleSelection: allowsMultiple) { result in
            switch result {
            case .success(let urls): Task { await importURLs(urls, kind: actions.importKind) }
            case .failure(let error): library.notice = "파일을 열지 못했습니다: \(error.localizedDescription)"
            }
        }
        .dropDestination(for: URL.self) { urls, _ in Task { await importURLs(urls, kind: .media) }; return true }
        .overlay(alignment: .top) {
            if let notice = library.notice {
                HStack { Text(notice).font(.callout); Button { library.notice = nil } label: { Image(systemName:"xmark.circle.fill") }.buttonStyle(.plain) }
                    .padding(14).background(.regularMaterial,in:RoundedRectangle(cornerRadius:14)).shadow(radius:8).padding(20).frame(maxWidth:650)
            }
        }
        .task(id: library.notice) { guard library.notice != nil else { return }; do { try await Task.sleep(for:.seconds(6)) } catch { return }; library.notice = nil }
        .confirmationDialog("이 곡의 순서표를 삭제할까요?", isPresented: Binding(get: { deleteID != nil }, set: { if !$0 { deleteID = nil } })) {
            Button("순서표 삭제", role: .destructive) { if let deleteID { session.deleteRoutine(deleteID) }; deleteID = nil }
        } message: { Text("원본 음원·영상은 유지됩니다.") }
        .onChange(of: library.data.settings) { _, _ in library.save() }
        #if os(macOS)
        .onExitCommand {
            if session.editing && !session.undo.isEmpty { session.undoEdit() }
            else { session.showEditor = false; session.editing = false; session.showSettings = false; session.focus = false }
        }
        #endif
        .task {
            await library.rescan()
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(3)) } catch { return }
                if scenePhase == .active { await library.rescan() }
            }
        }
    }
    @ViewBuilder private func workspace(wide: Bool) -> some View {
        #if os(macOS)
        HSplitView {
            PracticeWorkspace(wide: wide).frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
            if session.showEditor { EditorView().frame(minWidth: 310, idealWidth: 370, maxWidth: 520) }
        }
        #else
        PracticeWorkspace(wide: wide)
        #endif
    }
    private var importTypes: [UTType] {
        switch actions.importKind {
        case .folder, .folderReconnect: return [.folder]
        case .text: return [.plainText]
        case .backup: return [.json]
        case .link: return session.track?.isVideo == true ? [.audio] : [.movie, .video, .data]
        default: return [.audio,.movie,.video,.data]
        }
    }
    private var allowsMultiple: Bool { switch actions.importKind { case .media: return true; default: return false } }
    private func importURLs(_ urls: [URL], kind: AppActions.ImportKind) async {
        guard let first = urls.first else { return }
        switch kind {
        case .folder: await library.addFolder(first)
        case .folderReconnect(let id): await library.addFolder(first, replacing: id)
        case .text: session.importText(first)
        case .link:
            if let selected = session.selectedID, let added = library.addFiles([first]).first { library.link(selected, added); session.routine = library.routine(for: session.track) }
        case .reconnect(let id): library.reconnect(id, to: first); if id == session.selectedID { session.selectedID = nil; session.select(id, play: false) }
        case .backup: library.notice = "백업 가져오기를 준비하고 있습니다."
        case .media:
            var media: [URL] = []
            for url in urls {
                library.access(url)
                if (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true { await library.addFolder(url) }
                else if url.pathExtension.lowercased() == "txt" { session.importText(url) }
                else { media.append(url) }
            }
            let ids = library.addFiles(media)
            if let video = ids.first(where: { id in library.data.tracks.first(where: { $0.id == id })?.isVideo == true }) {
                library.data.settings.sideMode = .video; session.videoInStage = false; session.select(video)
            }
            if ids.isEmpty && !media.isEmpty { library.notice = "MP3, M4A, WAV, MP4, MOV 등의 음원·영상 파일을 선택해 주세요. WMA·WMV는 먼저 변환해야 합니다." }
        }
        if session.selectedID == nil, let first = library.data.tracks.first(where: { !$0.hidden && !$0.missing }) { session.select(first.id, play: false) }
    }
}
