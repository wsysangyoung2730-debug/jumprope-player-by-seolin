import SwiftUI
import UniformTypeIdentifiers

struct RootView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(PracticeSession.self) private var session
    @Environment(AppActions.self) private var actions
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasSeenGettingStartedTutorial") private var hasSeenTutorial = false
    @State private var visibility: NavigationSplitViewVisibility = .all
    @State private var initialSidebarWidth: Double?
    @State private var deleteID: UUID?
    @State private var pendingBackup: BackupPayload?
    var body: some View {
        @Bindable var session = session
        @Bindable var actions = actions
        NavigationSplitView(columnVisibility: $visibility) {
            LibraryView(deleteID: $deleteID)
                #if os(macOS)
                .frame(minWidth: 260)
                #endif
                .navigationSplitViewColumnWidth(min: 260, ideal: initialSidebarWidth ?? 300, max: 440)
                .onAppear {
                    if initialSidebarWidth == nil { initialSidebarWidth = min(440, max(280, library.data.settings.sidebarWidth)) }
                }
                .onGeometryChange(for: Double.self) { $0.size.width.rounded() } action: { width in
                    if (260...440).contains(width), abs(width - library.data.settings.sidebarWidth) >= 1 {
                        library.data.settings.sidebarWidth = width
                    }
                }
        } detail: {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    workspace(wide: geometry.size.width > 900)
                    Divider()
                    TransportView().frame(maxWidth:.infinity)
                }.frame(width:geometry.size.width,height:geometry.size.height)
            }
            .navigationTitle(session.track?.name ?? "JUMPROPE PLAYER")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(uiColor: .systemBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItemGroup {
                    Button { session.beginEditing() } label: { Label("순서표 편집", systemImage: "list.bullet.clipboard") }.disabled(session.selectedID == nil)
                    Button { actions.open(.link) } label: { Label("음원·영상 연결", systemImage: "link") }.disabled(session.selectedID == nil)
                    Button { session.focus.toggle() } label: { Label("집중 보기", systemImage: session.focus ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right") }
                    Button { session.showSettings = true } label: { Label("설정", systemImage: "slider.horizontal.3") }
                }
            }
        }
        #if os(macOS)
        .toolbarBackground(Color(nsColor:.windowBackgroundColor),for:.windowToolbar)
        .toolbarBackground(.visible,for:.windowToolbar)
        #else
        .toolbarBackground(Color(uiColor: .systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        #endif
        .tint(.blue)
        .onChange(of: session.focus) { _, value in visibility = value ? .detailOnly : .all }
        .sheet(isPresented: $actions.showTutorial, onDismiss: { hasSeenTutorial = true }) {
            TutorialView()
                #if os(iOS)
                .presentationDetents([.large])
                #endif
        }
        .task {
            #if DEBUG
            if StoreCapture.enabled {
                Task { await StoreCapture.run(session: session, actions: actions) }
                return
            }
            #endif
            if !hasSeenTutorial { actions.showTutorial = true }
        }
        .sheet(isPresented: $session.showSettings) { SettingsView().frame(minWidth: 300, idealWidth: 520, minHeight: 540) }
        #if os(iOS)
        .sheet(isPresented: $session.showEditor, onDismiss: { session.editing = false }) { EditorView().presentationDetents([.large]) }
        #endif
        .fileImporter(isPresented: $actions.showImporter, allowedContentTypes: importTypes, allowsMultipleSelection: allowsMultiple) { result in
            switch result {
            case .success(let urls):
                let kind = actions.importKind
                Task { await importURLs(urls, kind: kind) }
            case .failure(let error): library.notice = "파일을 열지 못했습니다: \(error.localizedDescription)"
            }
        }
        .fileExporter(isPresented:$actions.showExporter,document:BackupDocument(snapshot:library.data),contentType:.json,defaultFilename:"SEOLIN-JUMPROPE-backup") { result in
            if case .failure(let error) = result { library.notice = "백업 저장 실패: \(error.localizedDescription)" }
        }
        .confirmationDialog("백업 데이터를 가져올까요?",isPresented:Binding(get:{ pendingBackup != nil },set:{ if !$0 { pendingBackup = nil } })) {
            Button("가져오기") {
                guard let pendingBackup else { return }
                session.pause()
                do { try library.restore(pendingBackup); session.resetSelection() }
                catch { library.notice = "가져오지 못했습니다: \(error.localizedDescription)" }
                self.pendingBackup = nil
            }
        } message: { Text("앱 백업은 라이브러리를 교체하고, 브라우저 백업은 순서표를 연결합니다. 현재 데이터는 복구용 사본으로 보관합니다. 음원·영상 파일은 백업에 포함되지 않습니다.") }
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
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { library.save() }
            #if os(iOS)
            if phase == .background { session.pause() }
            #endif
        }
        #if os(macOS)
        .onExitCommand {
            if actions.showTutorial { actions.showTutorial = false }
            else if session.editing && !session.undo.isEmpty { session.undoEdit() }
            else { session.showEditor = false; session.editing = false; session.showSettings = false; session.focus = false }
        }
        #endif
        .task {
            await library.rescan(preserving:session.selectedID)
            if session.selectedID == nil, let first = library.data.tracks.filter({ !$0.hidden && !$0.missing }).sorted(by:{ $0.relativePath.localizedStandardCompare($1.relativePath) == .orderedAscending }).first { session.select(first.id,play:false) }
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(3)) } catch { return }
                if scenePhase == .active { await library.rescan(preserving:session.selectedID) }
            }
        }
    }
    @ViewBuilder private func workspace(wide: Bool) -> some View {
        #if os(macOS)
        HSplitView {
            PracticeWorkspace(wide: wide).frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity)
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
        case .backup:
            do { pendingBackup = try BackupPayload.decode(library.readImport(first)) }
            catch { library.notice = "백업을 읽지 못했습니다: \(error.localizedDescription)" }
        case .media:
            var media: [URL] = []
            var textFiles: [URL] = []
            for url in urls {
                if url.pathExtension.lowercased() != "txt" { library.access(url) }
                if (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true { await library.addFolder(url) }
                else if url.pathExtension.lowercased() == "txt" { textFiles.append(url) }
                else { media.append(url) }
            }
            let ids = library.addFiles(media)
            if let video = ids.first(where: { id in library.data.tracks.first(where: { $0.id == id })?.isVideo == true }) {
                library.data.settings.sideMode = .video; session.videoInStage = false; session.select(video)
            }
            if session.selectedID == nil, let id = ids.first { session.select(id,play:false) }
            if let text = textFiles.first { session.importText(text) }
            if ids.isEmpty && !media.isEmpty { library.notice = "MP3, M4A, WAV, MP4, MOV 등의 음원·영상 파일을 선택해 주세요. WMA·WMV는 먼저 변환해야 합니다." }
        }
        if session.selectedID == nil, let first = library.data.tracks.first(where: { !$0.hidden && !$0.missing }) { session.select(first.id, play: false) }
    }
}
