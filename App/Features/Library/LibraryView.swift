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
    @Environment(\.colorScheme) private var colorScheme
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
    private var sidebarBackground: Color {
        colorScheme == .dark ? Color(red:0.10,green:0.12,blue:0.15) : Color(red:0.96,green:0.97,blue:0.98)
    }
    private var cardBackground: Color {
        colorScheme == .dark ? Color(red:0.16,green:0.18,blue:0.22) : .white
    }
    private var textColor: Color {
        colorScheme == .dark ? .white : Color(red:0.10,green:0.14,blue:0.20)
    }
    private var detailColor: Color {
        colorScheme == .dark ? Color(red:0.74,green:0.78,blue:0.84) : Color(red:0.34,green:0.39,blue:0.46)
    }
    private let selectionColor = Color(red:0.12,green:0.30,blue:0.56)

    var body: some View {
        VStack(spacing:0) {
            VStack(spacing:16) {
                HStack(spacing:12) {
                    Image("SeolinLogo").resizable().scaledToFit()
                        .frame(width:36,height:34).padding(8)
                        .background(selectionColor,in:RoundedRectangle(cornerRadius:12))
                        .accessibilityLabel("서린태권도 로고")
                    VStack(alignment:.leading,spacing:3) {
                        Text("JUMPROPE").font(.system(size:17,weight:.bold))
                        Text("PLAYER by SEOLIN").font(.system(size:11,weight:.medium)).foregroundStyle(detailColor)
                    }
                    Spacer(minLength:0)
                }
                HStack(spacing:8) {
                    Button { actions.open(.folder) } label: {
                        Label("폴더 추가",systemImage:"folder.badge.plus")
                            .frame(maxWidth:.infinity,minHeight:36)
                            .background(cardBackground,in:RoundedRectangle(cornerRadius:8))
                            .overlay(RoundedRectangle(cornerRadius:8).stroke(detailColor.opacity(0.25)))
                    }.foregroundStyle(textColor)
                    Button { actions.open(.media) } label: {
                        Label("파일 추가",systemImage:"plus")
                            .frame(maxWidth:.infinity,minHeight:36)
                            .background(selectionColor,in:RoundedRectangle(cornerRadius:8))
                    }.foregroundStyle(.white)
                }.font(.system(size:12,weight:.semibold)).buttonStyle(.plain)
            }.padding(16)
            Divider()
            HStack(spacing:8) {
                Button { sourceID = nil; folder = ""; favorites = false } label: {
                    Image(systemName:"house.fill").frame(width:28,height:28)
                }.buttonStyle(.plain).help("전체 라이브러리").accessibilityLabel("전체 라이브러리")
                Image(systemName:"chevron.right").font(.caption2)
                Text(favorites ? "즐겨찾기" : (folder.isEmpty ? (library.data.sources.first { $0.id == sourceID }?.url.lastPathComponent ?? "라이브러리") : (folder as NSString).lastPathComponent))
                    .font(.system(size:12,weight:.medium)).lineLimit(1)
                Spacer(minLength:0)
                if sourceID != nil || !folder.isEmpty || favorites {
                    Button { up() } label: { Image(systemName:"arrow.up").frame(width:28,height:28) }
                        .buttonStyle(.plain).help("상위 폴더").accessibilityLabel("상위 폴더")
                }
            }.padding(.horizontal,12).padding(.vertical,8).foregroundStyle(detailColor)
            List {
                if sourceID == nil && folder.isEmpty && !favorites {
                    Button { favorites = true } label: {
                        HStack(spacing:10) {
                            Image(systemName:"star.fill").foregroundStyle(colorScheme == .dark ? .yellow : .orange)
                            Text("즐겨찾기").font(.system(size:13,weight:.semibold))
                            Spacer()
                            Image(systemName:"chevron.right").font(.caption).foregroundStyle(detailColor)
                        }.padding(12).background(cardBackground,in:RoundedRectangle(cornerRadius:10))
                    }.buttonStyle(.plain).foregroundStyle(textColor)
                        .listRowInsets(EdgeInsets(top:4,leading:12,bottom:8,trailing:12))
                        .listRowSeparator(.hidden).listRowBackground(Color.clear)
                }
                ForEach(entries) { entry in
                    row(entry)
                        .listRowInsets(EdgeInsets(top:4,leading:12,bottom:4,trailing:12))
                        .listRowSeparator(.hidden).listRowBackground(Color.clear)
                        .onDrag { dragged = entry.id; return NSItemProvider(object: entry.id as NSString) }
                        .onDrop(of: [.text], isTargeted: nil) { _ in let accepted = dragged != nil; reorder(before:entry.id); return accepted }
                }
                if entries.isEmpty {
                    Text("파일이나 폴더를 추가해\n연습을 시작하세요.").font(.callout).foregroundStyle(detailColor)
                        .padding(.vertical,20).listRowSeparator(.hidden).listRowBackground(Color.clear)
                }
                if sourceID == nil && !favorites {
                    let missing = library.data.tracks.filter { $0.missing && !$0.hidden }
                    if !missing.isEmpty {
                        Section("다시 연결할 파일") {
                            ForEach(missing) { track in
                                Button { actions.open(.reconnect(track.id)) } label: {
                                    Label(track.name,systemImage:"exclamationmark.triangle")
                                }.buttonStyle(.plain).foregroundStyle(textColor)
                                    .listRowBackground(cardBackground)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(sidebarBackground)
            Divider()
            Button { actions.showTutorial = true } label: {
                HStack(spacing:10) {
                    Image(systemName:"questionmark.circle")
                    Text("사용 가이드").font(.system(size:13,weight:.medium))
                    Spacer()
                    Image(systemName:"chevron.right").font(.caption)
                }.foregroundStyle(textColor).padding(.horizontal,16).padding(.top,14).padding(.bottom,2)
                    .contentShape(Rectangle())
            }.buttonStyle(.plain).help("파일 추가부터 구간 반복까지 알아보기")
            HStack {
                Text("\(library.data.tracks.filter { !$0.hidden && !$0.missing }.count)개 파일").foregroundStyle(detailColor)
                Spacer()
                Link("SEOLIN ↗",destination:URL(string:"https://www.instagram.com/seolin5_tkd/")!)
                    .fontWeight(.semibold).foregroundStyle(textColor)
            }.font(.caption).padding(16)
        }
        .foregroundStyle(textColor)
        .background(sidebarBackground.ignoresSafeArea())
        .navigationTitle("라이브러리")
    }
    @ViewBuilder private func row(_ entry: LibraryEntry) -> some View {
        if let track = entry.track {
            let selected = track.id == session.selectedID
            VStack(alignment:.leading,spacing:10) {
                HStack(alignment:.top,spacing:10) {
                    Image(systemName:track.isVideo ? "film" : "music.note")
                        .font(.system(size:17,weight:.medium)).frame(width:26,height:24)
                        .foregroundStyle(selected ? .white : textColor)
                    Text(track.name).font(.system(size:14,weight:.semibold)).lineLimit(3)
                        .fixedSize(horizontal:false,vertical:true).frame(maxWidth:.infinity,alignment:.leading)
                        .foregroundStyle(selected ? .white : textColor)
                        .help(track.name)
                }
                HStack(spacing:8) {
                    Label(track.routineID != nil ? "순서표 연결됨" : (track.isVideo ? "영상 파일" : "음원 파일"),systemImage:track.routineID != nil ? "link" : "doc")
                        .font(.system(size:11,weight:.medium)).lineLimit(1)
                        .foregroundStyle(selected ? Color.white.opacity(0.9) : detailColor)
                    Spacer(minLength:0)
                    Button { library.toggleFavorite(track.id) } label: {
                        Image(systemName:track.favorite ? "star.fill":"star")
                            .foregroundStyle(track.favorite ? (selected || colorScheme == .dark ? Color.yellow : Color.orange) : (selected ? .white : detailColor))
                            .frame(width:28,height:28).contentShape(Rectangle())
                    }.buttonStyle(.plain).help(track.favorite ? "즐겨찾기 해제" : "즐겨찾기 추가")
                        .accessibilityLabel(track.favorite ? "즐겨찾기 해제" : "즐겨찾기 추가")
                    Menu { trackMenu(track) } label: {
                        Image(systemName:"ellipsis").foregroundStyle(selected ? .white : textColor).frame(minWidth:22,minHeight:28)
                    }.menuStyle(.borderlessButton).fixedSize().tint(selected ? .white : textColor)
                        .help("파일 메뉴").accessibilityLabel("파일 메뉴")
                }
            }
            .padding(12).background(selected ? selectionColor : cardBackground,in:RoundedRectangle(cornerRadius:10))
            .overlay(RoundedRectangle(cornerRadius:10).stroke(selected ? Color.clear : detailColor.opacity(0.16)))
            .contentShape(Rectangle())
            .onTapGesture(count:2) { session.select(track.id,favorites:favorites); session.restart() }
            .onTapGesture { session.select(track.id,favorites:favorites) }
            .contextMenu { trackMenu(track) }
        } else {
            HStack(spacing:8) {
                Button { if let source = entry.source { sourceID = source.id; folder = "" } else if let path = entry.path { folder = path } } label: {
                    HStack(spacing:10) {
                        Image(systemName:"folder.fill").foregroundStyle(colorScheme == .dark ? .yellow : selectionColor)
                        Text(entry.name).font(.system(size:13,weight:.medium)).lineLimit(2)
                        Spacer(minLength:0)
                        Text("\(entry.count)").foregroundStyle(detailColor).font(.caption)
                        Image(systemName:"chevron.right").foregroundStyle(detailColor).font(.caption2)
                    }.padding(.vertical,8).contentShape(Rectangle())
                }.buttonStyle(.plain)
                if let source = entry.source, library.unavailableSources.contains(source.id) {
                    Button { actions.open(.folderReconnect(source.id)) } label: {
                        Image(systemName:"arrow.triangle.2.circlepath").frame(width:28,height:28)
                    }.buttonStyle(.plain).help("폴더 다시 연결").accessibilityLabel("폴더 다시 연결")
                }
            }.padding(.horizontal,12).padding(.vertical,4)
                .background(cardBackground,in:RoundedRectangle(cornerRadius:10))
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
