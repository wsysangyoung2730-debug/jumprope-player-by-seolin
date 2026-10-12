import SwiftUI
import UniformTypeIdentifiers

private struct LibraryEntry: Identifiable {
    let id: String
    let name: String
    var track: MediaTrack?
    var source: MediaSource?
    var path: String?
    var count = 0
}
struct LibraryView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(PracticeSession.self) private var session
    @Environment(AppActions.self) private var actions
    @Binding var deleteID: UUID?
    @State private var sourceID: UUID?
    @State private var folder = ""
    @State private var favorites = false
    @State private var dragged: String?
    private var orderKey: String { library.orderKey(folder: folder, source: sourceID) }
    private var entries: [LibraryEntry] {
        var result: [LibraryEntry] = []
        if favorites { return library.orderedTracks(favorites:true).map { LibraryEntry(id:$0.id.uuidString,name:$0.name,track:$0) } }
        if sourceID == nil && folder.isEmpty {
            result += library.data.sources.map { s in LibraryEntry(id:"source:\(s.id)",name:s.url.lastPathComponent,source:s,count:library.data.tracks.filter { $0.sourceID == s.id && !$0.hidden && !$0.missing }.count) }
        }
        let tracks = library.data.tracks.filter { !$0.hidden && !$0.missing && $0.sourceID == sourceID }
        let prefix = folder.isEmpty ? "" : folder + "/"
        let folders = Set(tracks.compactMap { t -> String? in
            guard t.relativePath.hasPrefix(prefix) else { return nil }
            let parts = String(t.relativePath.dropFirst(prefix.count)).split(separator:"/")
            return parts.count > 1 ? String(parts[0]) : nil
        })
        result += folders.map { name in LibraryEntry(id:"folder:\(prefix + name)",name:name,path:prefix+name,count:tracks.filter { $0.relativePath.hasPrefix(prefix+name+"/") }.count) }
        result += library.orderedTracks(folder:folder,sourceID:sourceID).map { LibraryEntry(id:$0.id.uuidString,name:$0.name,track:$0) }
        let order = library.data.orders[orderKey] ?? []
        return result.sorted { a,b in
            let x = order.firstIndex(of:a.id) ?? Int.max, y = order.firstIndex(of:b.id) ?? Int.max
            if x != y { return x < y }
            if (a.track == nil) != (b.track == nil) { return a.track == nil }
            return a.name.localizedStandardCompare(b.name) == .orderedAscending
        }
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName:"figure.jumprope").font(.title).foregroundStyle(.blue)
                VStack(alignment:.leading,spacing:2) { Text("JUMPROPE").font(.headline); Text("PLAYER by SEOLIN").font(.caption2).foregroundStyle(.secondary) }
                Spacer()
            }.padding(18)
            HStack { Button { actions.open(.folder) } label: { Label("폴더",systemImage:"folder.badge.plus") }; Button { actions.open(.media) } label: { Label("파일",systemImage:"plus") }; Spacer() }.padding(.horizontal,14).padding(.bottom,14)
            Divider()
            HStack {
                Button { sourceID = nil; folder = ""; favorites = false } label: { Image(systemName:"house") }.buttonStyle(.plain).help("전체 라이브러리")
                Image(systemName:"chevron.right").font(.caption2)
                Text(favorites ? "즐겨찾기" : (folder.isEmpty ? (library.data.sources.first { $0.id == sourceID }?.url.lastPathComponent ?? "라이브러리") : (folder as NSString).lastPathComponent)).font(.caption).lineLimit(1)
                Spacer()
                if sourceID != nil || !folder.isEmpty || favorites { Button { up() } label: { Image(systemName:"arrow.up") }.buttonStyle(.plain).help("상위 폴더") }
            }.padding(14).foregroundStyle(.secondary)
            List {
                if sourceID == nil && folder.isEmpty && !favorites {
                    Button { favorites = true } label: { Label("즐겨찾기",systemImage:"star.fill").foregroundStyle(.orange) }
                }
                ForEach(entries) { entry in
                    row(entry)
                        .onDrag { dragged = entry.id; return NSItemProvider(object: entry.id as NSString) }
                        .onDrop(of: [.text], isTargeted: nil) { _ in let accepted = dragged != nil; reorder(before:entry.id); return accepted }
                }
                if entries.isEmpty { Text("파일이나 폴더를 추가해\n연습을 시작하세요.").foregroundStyle(.secondary).padding(.vertical,20) }
                if sourceID == nil && !favorites {
                    let missing = library.data.tracks.filter { $0.missing && !$0.hidden }
                    if !missing.isEmpty {
                        Section("다시 연결할 파일") { ForEach(missing) { track in Button { actions.open(.reconnect(track.id)) } label: { Label(track.name,systemImage:"exclamationmark.triangle").foregroundStyle(.orange) } } }
                    }
                }
            }.listStyle(.sidebar)
            Divider()
            HStack {
                Text("\(library.data.tracks.filter { !$0.hidden && !$0.missing }.count)개 파일").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Link("SEOLIN ↗",destination:URL(string:"https://www.instagram.com/seolin5_tkd/")!).font(.caption2.bold())
            }.padding(14)
        }.navigationTitle("라이브러리")
    }
    @ViewBuilder private func row(_ entry: LibraryEntry) -> some View {
        if let track = entry.track {
            HStack(spacing:8) {
                Image(systemName:track.isVideo ? "film" : "music.note").foregroundStyle(track.id == session.selectedID ? .blue : .secondary)
                VStack(alignment:.leading,spacing:4) {
                    Text(track.name).lineLimit(2).font(.callout.weight(track.id == session.selectedID ? .semibold : .regular))
                    if track.routineID != nil { Text("순서표 연결됨").font(.caption2).foregroundStyle(.secondary) }
                }
                Spacer(minLength:2)
                Button { library.toggleFavorite(track.id) } label: { Image(systemName:track.favorite ? "star.fill":"star").foregroundStyle(track.favorite ? .orange : .secondary) }.buttonStyle(.borderless).help("즐겨찾기")
                Menu { trackMenu(track) } label: { Image(systemName:"ellipsis") }.menuStyle(.borderlessButton).fixedSize()
            }
            .padding(.vertical,5).contentShape(Rectangle())
            .listRowBackground(track.id == session.selectedID ? Color.blue.opacity(0.12) : Color.clear)
            .onTapGesture(count:2) { session.select(track.id,favorites:favorites); session.restart() }
            .onTapGesture { session.select(track.id,favorites:favorites) }
            .contextMenu { trackMenu(track) }
        } else {
            HStack {
                Button { if let source = entry.source { sourceID = source.id; folder = "" } else if let path = entry.path { folder = path } } label: {
                    HStack { Image(systemName:"folder.fill").foregroundStyle(.blue); Text(entry.name).lineLimit(1); Spacer(); Text("\(entry.count)").foregroundStyle(.secondary).font(.caption) }
                }.buttonStyle(.plain)
                if let source = entry.source, library.unavailableSources.contains(source.id) { Button { actions.open(.folderReconnect(source.id)) } label: { Image(systemName:"arrow.triangle.2.circlepath").foregroundStyle(.orange) }.buttonStyle(.borderless).help("폴더 다시 연결") }
            }.padding(.vertical,5)
        }
    }
    @ViewBuilder private func trackMenu(_ track: MediaTrack) -> some View {
        Button("재생") { session.select(track.id,favorites:favorites) }
        Button(track.routineID == nil ? "순서표 등록" : "순서표 수정") { session.select(track.id,play:false); session.beginEditing() }
        Button("파일 다시 연결…") { actions.open(.reconnect(track.id)) }
        Divider()
        Button("순서표 삭제",role:.destructive) { deleteID = track.id }.disabled(track.routineID == nil)
        Button("목록에서 제외",role:.destructive) { session.remove(track.id) }
    }
    private func up() { if favorites { favorites = false } else if folder.isEmpty { sourceID = nil } else { folder = (folder as NSString).deletingLastPathComponent } }
    private func reorder(before target: String) {
        guard let dragged, dragged != target else { return }
        var order = entries.map(\.id); order.removeAll { $0 == dragged }
        guard let index = order.firstIndex(of:target) else { return }; order.insert(dragged,at:index)
        if favorites { library.data.favorites = order.compactMap(UUID.init(uuidString:)) } else { library.data.orders[orderKey] = order }
        library.save(); self.dragged = nil
    }
}
