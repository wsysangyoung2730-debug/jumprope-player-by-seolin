import SwiftUI
struct EditorView: View {
    @Environment(PracticeSession.self) private var session
    @Environment(LibraryStore.self) private var library
    @Environment(AppActions.self) private var actions
    @State private var text = ""
    @FocusState private var textFocused: Bool
    @State private var base = Routine()
    var body: some View {
        VStack(spacing:0) {
            HStack { VStack(alignment:.leading,spacing:4) { Text("순서표 편집").font(.headline); Text(session.track?.name ?? "곡을 선택하세요").font(.caption).foregroundStyle(.secondary).lineLimit(1) }; Spacer(); Button { flush(); session.showEditor = false; session.editing = false } label: { Image(systemName:"xmark.circle.fill").foregroundStyle(.secondary) }.buttonStyle(.plain).help("편집 닫기") }.padding(20)
            Divider()
            ScrollView {
                VStack(alignment:.leading,spacing:18) {
                    TextField("예: 음악줄넘기 1단계",text:Binding(get:{ session.routine.title },set:{ title in session.change({ $0.title = title },remember:false) })).textFieldStyle(.roundedBorder).focusedValue(\.editingRoutineText, true)
                    VStack(alignment:.leading,spacing:8) {
                        Text("동작 순서").font(.subheadline.bold())
                        TextEditor(text:$text).focusedValue(\.editingRoutineText, true).font(.body).frame(minHeight:125,maxHeight:180).focused($textFocused).padding(7).background(.background,in:RoundedRectangle(cornerRadius:10)).overlay(RoundedRectangle(cornerRadius:10).stroke(.secondary.opacity(0.2)))
                        HStack { Button("텍스트 불러오기…") { flush(); actions.open(.text) }; Spacer(); Text("한 줄에 한 동작").font(.caption).foregroundStyle(.secondary) }
                    }
                    VStack(alignment:.leading,spacing:10) {
                        HStack { Circle().fill(session.editing ? .orange : .secondary).frame(width:7,height:7); Text(session.editing ? "싱크 기록 중" : "싱크 편집").font(.subheadline.bold()); Spacer(); Button(session.editing ? "끝내기" : "시작") { flush(); session.editing.toggle() }.buttonStyle(.borderless) }
                        Text("음악을 재생하고 동작이 바뀌는 순간 기록하세요.").font(.caption).foregroundStyle(.secondary)
                        Button { flush(); session.mark() } label: { Label("지금 싱크 찍기  ↵",systemImage:"record.circle").frame(maxWidth:.infinity) }.buttonStyle(.borderedProminent).controlSize(.large).disabled(!session.editing || session.routine.moves.isEmpty)
                        HStack { Button { session.undoEdit(); refreshText() } label: { Label("방금 것 취소",systemImage:"arrow.uturn.backward") }.disabled(session.undo.isEmpty); Spacer(); Button("전체 싱크 초기화") { session.clearTimes() }.font(.caption) }
                    }.padding(14).background(.orange.opacity(0.08),in:RoundedRectangle(cornerRadius:12))
                    ForEach(Array(session.routine.moves.enumerated()),id:\.element.id) { i,move in editorRow(i,move) }
                }.padding(20)
            }
            Divider()
            HStack { Image(systemName:"checkmark.circle"); Text("이 기기에 자동 저장"); Spacer(); Text("\(session.routine.moves.count)개 동작") }.font(.caption).foregroundStyle(.secondary).padding(16)
        }
        .background(.regularMaterial)
        .onAppear { refreshText() }
        .onChange(of: session.selectedID) { _,_ in refreshText() }
        .onChange(of: session.routine.text) { _,_ in if !textFocused { refreshText() } }
        .onChange(of: text) { _,_ in if textFocused { flush(normalize:false) } }
        .onChange(of: textFocused) { _,focused in if focused { base = session.routine } else { flush() } }
        .disabled(session.selectedID == nil)
    }
    private func refreshText() { text = session.routine.text; base = session.routine }
    private func flush(normalize:Bool = true) {
        if text != session.routine.text {
            var parsed = base
            for i in parsed.moves.indices { if let current = session.routine.moves.first(where:{ $0.id == parsed.moves[i].id }) { parsed.moves[i].time = current.time } }
            parsed.title = session.routine.title
            parsed.setText(text)
            session.change({ $0 = parsed },remember:false)
        }
        if normalize { refreshText() }
    }
    private func editorRow(_ i:Int,_ move:Move) -> some View {
        VStack(alignment:.leading,spacing:10) {
            HStack {
                Text("\(i+1)").font(.caption.bold()).frame(width:24,height:24).background(.blue.opacity(0.12),in:Circle())
                Text(move.name).font(.callout.weight(.medium)); Spacer()
                if session.active == i { Image(systemName:"waveform").foregroundStyle(.blue) }
            }.contentShape(Rectangle()).onTapGesture { if session.editing && move.time == nil { session.mark(i) } else { session.pick(i) } }
            HStack(spacing:10) {
                Button { session.setTime(i,(move.time ?? 0)-0.1) } label: { Image(systemName:"minus") }.disabled(move.time == nil)
                Text(move.time.map { timeText($0,precise:true) } ?? "미설정").font(.system(.caption,design:.monospaced)).frame(minWidth:58)
                Button { session.setTime(i,(move.time ?? 0)+0.1) } label: { Image(systemName:"plus") }.disabled(move.time == nil)
                Spacer()
                Button("다시 찍기") { session.setTime(i,session.time) }.font(.caption)
                Button { session.setTime(i,nil) } label: { Image(systemName:"xmark") }.help("이 싱크만 삭제").disabled(move.time == nil)
            }.buttonStyle(.borderless)
        }.padding(12).background(.background,in:RoundedRectangle(cornerRadius:10)).overlay(RoundedRectangle(cornerRadius:10).stroke(session.editing && session.markIndex == i ? .orange : .secondary.opacity(0.15),lineWidth:session.markIndex == i ? 2 : 1))
    }
}
