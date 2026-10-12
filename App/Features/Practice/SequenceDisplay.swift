import SwiftUI

struct SequenceDisplay: View {
    @Environment(PracticeSession.self) private var session
    @Environment(LibraryStore.self) private var library
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let primary: Bool
    let scrolling: Bool
    @State private var dragStart: Int?
    private var alignment: Alignment { primary || library.data.settings.alignment == "center" ? .center : library.data.settings.alignment == "right" ? .trailing : .leading }
    var body: some View {
        GeometryReader { geometry in
            let rowHeight = scrolling ? max(64,geometry.size.height/3.3) : max(primary ? 38 : 36,min(62,geometry.size.height/Double(max(1,session.routine.moves.count+1))))
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment:.leading,spacing: scrolling ? 8 : 4) {
                        if !session.routine.title.isEmpty { Text(session.routine.title).font(.headline).foregroundStyle(.secondary).frame(maxWidth:.infinity,alignment:alignment).padding(.vertical,12) }
                        ForEach(Array(session.routine.moves.enumerated()),id:\.element.id) { index,move in
                            row(index,move,height:rowHeight)
                                .id(move.id)
                                .onTapGesture { session.pick(index) }
                                #if os(macOS)
                                .simultaneousGesture(DragGesture(minimumDistance:8).onChanged { _ in dragStart = index }.onEnded { value in
                                    let end = min(session.routine.moves.count-1,max(0,index+Int((value.translation.height/(rowHeight+4)).rounded())))
                                    if end != index, let a = session.routine.span(min(index,end),duration:session.duration), let b = session.routine.span(max(index,end),duration:session.duration) { session.setLoop(.combining(a,b)) }
                                    dragStart = nil
                                })
                                #endif
                        }
                    }.padding(.vertical,scrolling ? max(0,(geometry.size.height-rowHeight)/2) : 4)
                }
                .onChange(of: session.active) { _, index in
                    guard let index, session.routine.moves.indices.contains(index), scrolling || !primary else { return }
                    withAnimation(reduceMotion ? nil : .easeInOut(duration:0.3)) { proxy.scrollTo(session.routine.moves[index].id,anchor:.center) }
                }
            }
        }
    }
    private func row(_ index:Int,_ move:Move,height:Double) -> some View {
        let current = session.active == index
        let inLoop = move.time.map { time in session.loop.map { time >= $0.start && time < $0.end } ?? false } ?? false
        return HStack(spacing:12) {
            Text(String(format:"%02d",index+1)).font(.system(size:primary ? 14 : 12,weight:.medium,design:.monospaced)).opacity(0.5)
            Text(move.name).font(.system(size:primary ? (current ? 28 : 20) : library.data.settings.textSize,weight:current ? .bold : .medium)).lineLimit(3).minimumScaleFactor(0.65)
            if current { Image(systemName:"waveform").font(.caption) }
        }
        .frame(maxWidth:.infinity,minHeight:height,alignment:alignment).padding(.horizontal,14)
        .background(current ? (primary ? Color.yellow : Color.blue).opacity(primary ? 1 : 0.14) : inLoop ? Color.blue.opacity(0.13) : Color.clear,in:RoundedRectangle(cornerRadius:12))
        .foregroundStyle(current && primary ? Color(red:0.05,green:0.1,blue:0.2) : primary ? .white : .primary)
        .opacity(session.active.map { index < $0 && !current ? 0.45 : 1 } ?? 1)
        .overlay(RoundedRectangle(cornerRadius:12).stroke(inLoop ? Color.blue : .clear,lineWidth:1))
        .contentShape(Rectangle())
        .accessibilityLabel("\(index+1)번 \(move.name)\(current ? ", 현재 동작" : "")")
    }
}
