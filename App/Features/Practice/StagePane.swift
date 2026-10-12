import SwiftUI
import AVKit

struct StagePane: View {
    @Environment(PracticeSession.self) private var session
    @Environment(LibraryStore.self) private var library
    @Environment(AppActions.self) private var actions
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    let primary: Bool
    private let navy = Color(red:0.035,green:0.09,blue:0.20)
    private var mode: DisplayMode { primary ? library.data.settings.stageMode : library.data.settings.sideMode }
    private var showsVideo: Bool {
        if library.data.settings.stageMode == .video && library.data.settings.sideMode == .video { return primary == session.videoInStage }
        return mode == .video
    }
    var body: some View {
        VStack(spacing:0) {
            HStack {
                Text(primary ? "연습 무대" : "보조 화면").font(.caption.weight(.semibold)).foregroundStyle(primary ? .white.opacity(0.5) : .secondary)
                Spacer()
                if !primary && mode != .video {
                    Menu {
                        Button("왼쪽 정렬") { library.data.settings.alignment = "left" }
                        Button("가운데 정렬") { library.data.settings.alignment = "center" }
                        Button("오른쪽 정렬") { library.data.settings.alignment = "right" }
                        Divider()
                        Button("글자 크게") { library.data.settings.textSize = min(48,library.data.settings.textSize + 2) }
                        Button("글자 작게") { library.data.settings.textSize = max(12,library.data.settings.textSize - 2) }
                    } label: { Image(systemName:"textformat.size") }
                }
            }.padding(.horizontal,22).padding(.top,20).padding(.bottom,12)
            Picker("보기",selection:Binding(get:{ mode },set:{ value in
                if primary { library.data.settings.stageMode = value } else { library.data.settings.sideMode = value }
                if value == .video { session.videoInStage = primary }
            })) { ForEach(DisplayMode.allCases,id:\.self) { Text($0.title).tag($0) } }.pickerStyle(.segmented).labelsHidden().padding(.horizontal,18).padding(.bottom,16)
            if primary && library.data.settings.countSeconds > 0 { nextCue.padding(.bottom,16) }
            ZStack {
                if mode == .video {
                    if session.hasVideo && showsVideo {
                        VStack(spacing:8) {
                            MediaSurface(player:session.player).onTapGesture { session.toggle() }
                                .frame(maxWidth:.infinity,maxHeight:primary ? .infinity : library.data.settings.videoHeight)
                            if !primary {
                                Slider(value:Binding(get:{ library.data.settings.videoHeight },set:{ library.data.settings.videoHeight = $0 }),in:120...700).help("영상 높이")
                                Spacer(minLength:0)
                            }
                        }
                    } else {
                        empty(icon:"film",title:showsVideo ? "시범 영상을 함께 보세요" : "영상은 다른 화면에 표시 중입니다",description:"영상과 순서표를 나란히 보며 연습할 수 있어요.") { actions.open(.media) }
                    }
                } else if session.routine.moves.isEmpty {
                    empty(icon:"figure.jumprope",title:session.selectedID == nil ? "오늘의 연습을 시작하세요" : "동작 순서표를 만들어 보세요",description:session.selectedID == nil ? "왼쪽에서 음악 또는 영상을 선택해 주세요." : "동작을 입력하고 음악에 맞춰 싱크를 기록하세요.") { if session.selectedID == nil { actions.open(.media) } else { session.beginEditing() } }
                } else {
                    SequenceDisplay(primary:primary,scrolling:mode == .rise)
                }
                if primary, let count = session.countdown {
                    RoundedRectangle(cornerRadius:28).fill(.black.opacity(0.72))
                    VStack(spacing:12) { Text("준비").font(.title3).foregroundStyle(.white.opacity(0.65)); Text(count == 0 ? "시작!" : "\(count)").font(.system(size:110,weight:.heavy,design:.rounded)).foregroundStyle(.yellow) }.allowsHitTesting(false)
                }
                if session.loading { ProgressView().controlSize(.large) }
            }.padding(.horizontal,primary ? 20 : 10).padding(.bottom,12)
            if primary {
                HStack { Image(systemName:session.track?.isVideo == true ? "film" : "waveform"); Text(session.track?.name ?? "JUMPROPE PLAYER by SEOLIN").lineLimit(1); Spacer(); if session.editing { Label("싱크 편집 중",systemImage:"record.circle").foregroundStyle(.yellow) } }.font(.caption).foregroundStyle(.white.opacity(0.55)).padding(20)
            }
        }
        .frame(maxWidth:.infinity,maxHeight:.infinity)
        .background(primary ? navy : Color.secondary.opacity(0.055))
        .foregroundStyle(primary ? Color.white : Color.primary)
        .environment(\.colorScheme, primary ? .dark : colorScheme)
        .simultaneousGesture(DragGesture(minimumDistance:40).onEnded { value in
            #if os(iOS)
            if !session.playing && abs(value.translation.height) > abs(value.translation.width) { session.step(value.translation.height < 0 ? 1 : -1) }
            #endif
        })
        #if os(macOS)
        .background(WheelBridge(enabled:!session.playing && session.countdown == nil && !session.routine.moves.isEmpty) { session.step($0) })
        #endif
    }
    @ViewBuilder private var nextCue: some View {
        let next = session.next
        let remaining = next.flatMap { session.routine.moves[$0].time }.map { max(0,$0-session.time) }
        VStack(spacing:4) {
            Text(remaining == nil ? "NEXT MOVE" : "다음 동작까지").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(.white.opacity(0.5))
            if let remaining {
                HStack(alignment:.firstTextBaseline,spacing:5) {
                    Text("\(Int(ceil(remaining)))").font(.system(size:remaining <= Double(library.data.settings.countSeconds) ? 60 : 36,weight:.bold,design:.rounded)).contentTransition(.numericText())
                    Text("초").font(.title3)
                }.foregroundStyle(remaining <= Double(library.data.settings.countSeconds) ? .yellow : .white)
                if let next { Text("\(next+1). \(session.routine.moves[next].name)").font(.callout).foregroundStyle(.white.opacity(0.75)) }
            } else { Text(session.active != nil ? "마지막 동작" : (session.routine.moves.isEmpty ? "준비" : "싱크 대기")).font(.title2.bold()).foregroundStyle(.white.opacity(0.75)) }
        }.frame(height:115)
    }
    private func empty(icon:String,title:String,description:String,action:@escaping () -> Void) -> some View {
        VStack(spacing:18) {
            Image(systemName:icon).font(.system(size:48,weight:.light)).foregroundStyle(primary ? .yellow : .blue)
            Text(title).font(.title3.bold()).multilineTextAlignment(.center)
            Text(description).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button(mode == .video ? "영상 파일 열기" : session.selectedID == nil ? "파일 열기" : "순서표 등록",action:action).buttonStyle(.borderedProminent).controlSize(.large)
        }.padding(26).frame(maxWidth:.infinity,maxHeight:.infinity)
    }
}
