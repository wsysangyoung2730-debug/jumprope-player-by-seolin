import SwiftUI
struct TransportView: View {
    @Environment(PracticeSession.self) private var session
    @Environment(LibraryStore.self) private var library
    var body: some View {
        VStack(spacing:14) {
            HStack {
                VStack(alignment:.leading,spacing:3) { Text(session.track?.name ?? "선택된 곡 없음").font(.callout.weight(.semibold)).lineLimit(1); Text(session.loop.map { "반복 \(timeText($0.start)) – \(timeText($0.end))" } ?? "음악과 함께, 한 동작씩").font(.caption).foregroundStyle(.secondary) }
                Spacer()
                Text("\(timeText(session.time)) / \(timeText(session.duration))").font(.system(.caption,design:.monospaced)).foregroundStyle(.secondary)
            }
            TimelineView()
            HStack(alignment:.bottom,spacing:16) {
                ViewThatFits {
                    HStack(spacing:24) { playback; Spacer(); repeats }
                    VStack(spacing:14) { playback; repeats }
                }.frame(maxWidth:.infinity)
                SeolinBrandBadge()
            }
        }.padding(.horizontal,24).padding(.vertical,18).background(.bar)
    }
    private var playback: some View {
        HStack(spacing:22) {
            Button { session.go(-1) } label: { Image(systemName:"backward.end.fill").font(.title3) }.help("이전 곡")
            Button { session.toggle() } label: { Image(systemName:session.playing || session.countdown != nil ? "pause.fill" : "play.fill").font(.title2).frame(width:48,height:48).background(.blue,in:Circle()).foregroundStyle(.white) }.help("재생 / 일시정지 (Space)")
            Button { session.go(1) } label: { Image(systemName:"forward.end.fill").font(.title3) }.help("다음 곡")
        }.buttonStyle(.plain).disabled(session.selectedID == nil)
    }
    private var repeats: some View {
        ViewThatFits {
            repeatButtons.labelStyle(.titleAndIcon)
            repeatButtons.labelStyle(.iconOnly)
        }
    }
    private var repeatButtons: some View {
        HStack(spacing:10) {
            Button { library.data.settings.repeatMode = library.data.settings.repeatMode == .all ? .off : .all } label: { Label("전체 반복",systemImage:"repeat") }.tint(library.data.settings.repeatMode == .all ? .blue : .secondary)
            Button { library.data.settings.repeatMode = library.data.settings.repeatMode == .one ? .off : .one } label: { Label("1곡 반복",systemImage:"repeat.1") }.tint(library.data.settings.repeatMode == .one ? .blue : .secondary)
            Button { session.toggleLoop() } label: { Label("구간 반복",systemImage:"repeat.circle") }.tint(session.loopEnabled ? .orange : .secondary)
        }.buttonStyle(.bordered).controlSize(.regular)
    }
}
struct TimelineView: View {
    @Environment(PracticeSession.self) private var session
    @State private var preview: TimeRange?
    @State private var edge: Bool?
    @State private var started = false
    @State private var selecting = false
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let total = max(0.1,session.duration)
            ZStack(alignment:.leading) {
                Capsule().fill(Color.secondary.opacity(0.16)).frame(height:8)
                Capsule().fill(.blue).frame(width:max(0,min(width,session.time/total*width)),height:8)
                ForEach(session.routine.moves.filter { $0.time != nil }) { move in Rectangle().fill(Color.secondary.opacity(0.55)).frame(width:2,height:16).offset(x:max(0,min(width,(move.time ?? 0)/total*width))) }
                if let range = preview ?? session.loop {
                    RoundedRectangle(cornerRadius:4).fill(.orange.opacity(0.28)).frame(width:max(0,(range.end-range.start)/total*width),height:24).offset(x:range.start/total*width)
                    ForEach([range.start,range.end],id:\.self) { value in Capsule().fill(.orange).frame(width:7,height:28).offset(x:value/total*width-3) }
                }
                Circle().fill(.blue).frame(width:14,height:14).offset(x:max(0,min(width,session.time/total*width))-7)
            }.frame(height:32).contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance:0).onChanged { value in
                guard session.duration > 0 else { return }
                if !started {
                    started = true
                    let x = value.startLocation.x
                    if let range = session.loop {
                        if abs(x-range.start/total*width) < 18 { edge = true } else if abs(x-range.end/total*width) < 18 { edge = false }
                    }
                    selecting = session.loopEnabled
                    #if os(macOS)
                    selecting = selecting || NSEvent.modifierFlags.contains(.shift)
                    #endif
                }
                let t = snapped(value.location.x,width:width)
                if let edge, let loop = session.loop {
                    preview = TimeRange(start:min(edge ? t : loop.start,edge ? loop.end : t),end:max(edge ? t : loop.start,edge ? loop.end : t))
                } else if selecting {
                    let start = snapped(value.startLocation.x,width:width)
                    preview = TimeRange(start:min(start,t),end:max(start,t))
                } else { session.seek(t,play:session.time >= session.duration) }
            }.onEnded { value in
                defer { preview = nil; edge = nil; started = false }
                if edge != nil, let preview { session.adjustLoop(preview) }
                else if selecting && abs(value.translation.width) > 4, let preview { session.setLoop(preview) }
                else if session.loopEnabled && (session.loop == nil || session.pendingRange != nil) { let t = snapped(value.location.x,width:width); session.pickRange(TimeRange(start:t,end:t)) }
                else { session.seek(snapped(value.location.x,width:width)) }
            })
            .accessibilityElement().accessibilityLabel("재생 위치").accessibilityValue(timeText(session.time))
            .accessibilityAdjustableAction { direction in session.seek(session.time + (direction == .increment ? 1 : -1)) }
        }.frame(height:32)
    }
    private func snapped(_ x:Double,width:Double) -> Double {
        let time = max(0,min(1,x/max(1,width))) * session.duration
        let tolerance = 12/max(1,width)*session.duration
        return session.routine.moves.compactMap(\.time).filter { $0 <= session.duration && abs($0-time) < tolerance }.min(by:{ abs($0-time) < abs($1-time) }) ?? time
    }
}
