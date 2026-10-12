import SwiftUI
import AVKit

struct PracticeWorkspace: View {
    @Environment(PracticeSession.self) private var session
    @Environment(LibraryStore.self) private var library
    let wide: Bool
    @State private var showCompanion = true
    var body: some View {
        #if os(macOS)
        HSplitView {
            StagePane(primary:true).frame(minWidth:320,maxWidth:.infinity,maxHeight:.infinity)
            if showCompanion && (!session.showEditor || wide) { StagePane(primary:false).frame(minWidth:200,idealWidth:library.data.settings.sideWidth,maxWidth:400,maxHeight:.infinity)
                .onGeometryChange(for: Double.self) { $0.size.width } action: { if $0 >= 200 { library.data.settings.sideWidth = $0 } } }
        }
        .toolbar { ToolbarItem { Button { showCompanion.toggle() } label: { Label("보조 화면",systemImage:"rectangle.righthalf.inset.filled") } } }
        #else
        if wide {
            HStack(spacing:1) { StagePane(primary:true); StagePane(primary:false).frame(width:320) }
        } else {
            VStack(spacing:0) {
                Picker("화면",selection:$showCompanion) { Text("연습 무대").tag(false); Text("보조 화면").tag(true) }.pickerStyle(.segmented).padding(10)
                StagePane(primary:!showCompanion)
            }.onAppear { showCompanion = false }
        }
        #endif
    }
}
