import SwiftUI

@main
struct JumpRopePlayerApp: App {
    @State private var library: LibraryStore
    @State private var session: PracticeSession
    @State private var actions = AppActions()
    init() {
        let store: LibraryStore
        #if DEBUG
        store = CommandLine.arguments.contains("--qa-demo") ? QASeed.library() : LibraryStore()
        #else
        store = LibraryStore()
        #endif
        let practice = PracticeSession(library:store)
        #if DEBUG
        if CommandLine.arguments.contains("--qa-demo"), let first = store.data.tracks.first { practice.select(first.id,play:false) }
        #endif
        _library = State(initialValue:store); _session = State(initialValue:practice)
    }
    var body: some Scene {
        #if os(macOS)
        Window("JUMPROPE PLAYER by SEOLIN", id: "player") {
            RootView().environment(library).environment(session).environment(actions)
                .frame(minWidth: 900, minHeight: 620)
        }
        .defaultSize(width: 1420, height: 880)
        .commands { playerCommands }
        Settings { SettingsView().environment(library).environment(session).environment(actions).frame(width: 520, height: 610) }
        #else
        WindowGroup { RootView().environment(library).environment(session).environment(actions) }
        .commands { playerCommands }
        #endif
    }
    @CommandsBuilder var playerCommands: some Commands {
        CommandGroup(replacing: .help) {
            Button("JUMPROPE PLAYER 사용 가이드…") { actions.showTutorial = true }
                .disabled(session.showSettings || actions.showImporter || actions.showExporter)
        }
        CommandGroup(replacing: .newItem) {
            Group {
                Button("파일 추가…") { actions.open(.media) }.keyboardShortcut("o")
                Button("음원 폴더 열기…") { actions.open(.folder) }.keyboardShortcut("o", modifiers: [.command,.shift])
                Button("순서표 텍스트 불러오기…") { actions.open(.text) }.disabled(session.selectedID == nil)
            }.disabled(actions.showTutorial)
        }
        CommandMenu("재생") {
            Group {
                Button(session.playing ? "일시정지" : "재생") { session.toggle() }.keyboardShortcut(.space, modifiers: [])
                Button("처음부터 재생") { session.restart() }.keyboardShortcut("r", modifiers: .command)
                Button("이전 곡") { session.go(-1) }.keyboardShortcut(.leftArrow, modifiers: .command)
                Button("다음 곡") { session.go(1) }.keyboardShortcut(.rightArrow, modifiers: .command)
                Divider()
                Button("이전 동작") { session.step(-1) }.keyboardShortcut(.upArrow, modifiers: [])
                Button("다음 동작") { session.step(1) }.keyboardShortcut(.downArrow, modifiers: [])
                Button("구간 반복") { session.toggleLoop() }.keyboardShortcut("l")
            }.disabled(actions.showTutorial)
        }
        CommandMenu("순서표") {
            Group {
                Button("순서표 싱크 편집") { session.beginEditing() }.keyboardShortcut("e")
                Button("지금 싱크 찍기") { session.mark() }.keyboardShortcut(.return, modifiers: []).disabled(!session.editing)
                Button("싱크 실행 취소") { session.undoEdit() }.keyboardShortcut("z").disabled(session.undo.isEmpty)
                Button("음원·영상 연결…") { actions.open(.link) }.disabled(session.selectedID == nil)
                Button("목록에서 제외") { if let id = session.selectedID { session.remove(id) } }.keyboardShortcut(.delete, modifiers: [])
            }.disabled(actions.showTutorial)
        }
        CommandMenu("연습 화면") {
            Group {
                Button(session.focus ? "기본 화면" : "집중 보기") { session.focus.toggle() }.keyboardShortcut("f", modifiers: [.command,.shift])
                Link("서린태권도 Instagram", destination: URL(string:"https://www.instagram.com/seolin5_tkd/")!)
            }.disabled(actions.showTutorial)
        }
    }
}
