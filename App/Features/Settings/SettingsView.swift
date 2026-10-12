import SwiftUI

struct SettingsView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(PracticeSession.self) private var session
    @Environment(AppActions.self) private var actions
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        @Bindable var library = library
        VStack(spacing:0) {
            HStack { Text("플레이어 설정").font(.title2.bold()); Spacer(); Button("완료") { library.save(); session.showSettings = false; dismiss() } }.padding(22)
            Form {
                Section("동작 안내") {
                    Picker("다음 동작 카운트",selection:$library.data.settings.countSeconds) { Text("끄기").tag(0); Text("3초").tag(3); Text("5초").tag(5); Text("10초").tag(10) }
                    Toggle("동작 카운트 알림음",isOn:$library.data.settings.countSound)
                }
                Section("싱크 편집") {
                    HStack { Text("자동 입력 간격"); Spacer(); TextField("초",value:$library.data.settings.autoGap,format:.number.precision(.fractionLength(1))).frame(width:85); Text("초") }
                    Text("0이면 끕니다. 동작 하나를 찍으면 뒤 동작을 이 간격으로 자동 기록합니다.").font(.caption).foregroundStyle(.secondary)
                }
                Section("구간 반복") {
                    Stepper("준비 카운트: \(library.data.settings.loopCount)초",value:$library.data.settings.loopCount,in:0...30)
                    Toggle("반복 준비 알림음",isOn:$library.data.settings.loopSound)
                }
                Section("라이브러리") {
                    Text("연결한 폴더 \(library.data.sources.count)개").foregroundStyle(.secondary)
                    Button("폴더 다시 확인") { library.restoreAccess(); Task { await library.rescan() } }
                    Button("기억한 폴더 모두 지우기",role:.destructive) { library.forgetFolders() }
                    Button("백업 내보내기…") { actions.showExporter = true; session.showSettings = false; dismiss() }
                    Button("백업·브라우저 데이터 가져오기…") { session.showSettings = false; dismiss(); actions.open(.backup) }
                }
                Section {
                    Text("JUMPROPE PLAYER by SEOLIN").font(.headline)
                    Text("음악과 동작을 연결하는 줄넘기 연습 공간").font(.caption).foregroundStyle(.secondary)
                    Link("서린태권도 Instagram",destination:URL(string:"https://www.instagram.com/seolin5_tkd/")!)
                }
            }.formStyle(.grouped).focusedValue(\.editingRoutineText, true)
        }
        .onChange(of: library.data.settings) { _,value in
            if !value.autoGap.isFinite { library.data.settings.autoGap = 0 }
            else if !(0...86_400).contains(value.autoGap) { library.data.settings.autoGap = min(86_400,max(0,value.autoGap)) }
            library.save()
        }
    }
}
