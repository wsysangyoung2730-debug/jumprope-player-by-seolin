import SwiftUI

private struct TutorialStep {
    let label: String
    let symbol: String
    let title: String
    let summary: String
    let instructions: [(title: String, detail: String)]
    let macTip: String
    let iPadTip: String

    static let all: [TutorialStep] = [
        TutorialStep(label:"파일", symbol:"folder.badge.plus", title:"연습할 음악부터 골라요",
            summary:"음원이나 시범 영상을 라이브러리에 추가하면 준비 완료예요.",
            instructions:[
                ("파일 또는 폴더 추가", "왼쪽 위 ‘파일 추가’로 음원·영상을 선택하거나, ‘폴더 추가’로 연습 자료가 담긴 폴더를 연결하세요."),
                ("연습할 파일 선택", "라이브러리에서 파일을 선택하면 재생 화면에 연결됩니다. 영상은 보조 화면에서 볼 수 있어요."),
                ("재생 버튼 누르기", "화면 아래의 ▶ 버튼으로 재생하고, 재생 막대를 움직여 원하는 위치로 이동하세요.")
            ], macTip:"⌘O 파일 추가 · ⇧⌘O 폴더 추가 · Space 재생 / 일시정지",
            iPadTip:"파일 앱에서 음원이나 영상을 선택하세요. 재생 막대는 손가락으로 움직일 수 있어요."),
        TutorialStep(label:"순서표", symbol:"list.bullet.clipboard", title:"동작을 한 줄씩 적어요",
            summary:"음악에 맞출 동작 목록을 먼저 만들어 주세요.",
            instructions:[
                ("순서표 편집 열기", "파일을 선택한 뒤 화면 위의 ‘순서표 편집’을 누르세요."),
                ("제목과 동작 입력", "예를 들어 제목은 ‘음악줄넘기 1단계’, 동작은 ‘모아뛰기’, ‘번갈아 뛰기’, ‘이중뛰기’를 한 줄씩 적으세요."),
                ("기존 순서표도 가져오기", "‘텍스트 불러오기…’에서 TXT 파일을 선택할 수 있어요. 편집한 내용은 자동으로 저장됩니다.")
            ], macTip:"⌘E 순서표 편집 · 오른쪽 편집 패널에서 음악을 들으며 작업하세요.",
            iPadTip:"순서표 편집은 별도 화면으로 열려요. 글을 입력한 뒤 키보드를 내려 싱크 기록 버튼을 확인하세요."),
        TutorialStep(label:"싱크", symbol:"record.circle", title:"동작이 바뀌는 순간을 찍어요",
            summary:"음악의 어느 시점에 어떤 동작을 할지 연결하는 과정이에요.",
            instructions:[
                ("싱크 기록 상태 확인", "편집 화면에 ‘싱크 기록 중’이 보이는지 확인하세요. 멈춰 있다면 ‘시작’을 누르세요."),
                ("음악에 맞춰 기록", "음악을 재생하고 동작이 시작되는 순간마다 ‘지금 싱크 찍기’를 누르세요. 다음 동작으로 자동 이동합니다."),
                ("어긋난 시간 다듬기", "‘방금 것 취소’로 되돌리거나, 각 동작의 − / + 버튼으로 0.1초씩 조정하세요. ‘다시 찍기’는 현재 재생 시간을 기록합니다.")
            ], macTip:"Enter 싱크 기록 · ⌘Z 실행 취소. 텍스트 입력칸 밖을 선택한 뒤 단축키를 사용하세요.",
            iPadTip:"‘지금 싱크 찍기’ 버튼으로 기록하세요. 일정한 간격이 필요하면 설정의 ‘자동 입력 간격’을 이용하세요."),
        TutorialStep(label:"화면", symbol:"rectangle.split.2x1", title:"연습에 맞게 화면을 골라요",
            summary:"동작 안내와 영상을 함께 보며 음악에 맞춰 연습하세요.",
            instructions:[
                ("무대와 보조 화면 선택", "각 화면 위의 보기 선택에서 순서표, 자동 스크롤, 영상을 바꿀 수 있어요."),
                ("시범 영상과 순서표 연결", "‘음원·영상 연결’로 다른 미디어 파일을 선택하면 같은 순서표를 공유합니다. 두 파일을 동시에 재생하는 기능은 아니에요."),
                ("동작 안내 설정", "설정에서 다음 동작 카운트와 알림음을 조절하세요. ‘집중 보기’로 라이브러리를 접을 수도 있어요.")
            ], macTip:"화면 사이 경계를 드래그해 너비를 조절하세요. ⇧⌘F로 집중 보기를 켜고 끌 수 있어요.",
            iPadTip:"넓은 화면에서는 나란히, 좁은 화면에서는 ‘연습 무대 / 보조 화면’을 전환하며 볼 수 있어요."),
        TutorialStep(label:"반복", symbol:"repeat", title:"어려운 구간만 반복해요",
            summary:"동작 몇 개를 골라 준비 카운트와 함께 반복 연습하세요.",
            instructions:[
                ("구간 반복 켜기", "화면 아래의 ‘구간 반복’을 누르세요. 동작을 기준으로 고르려면 먼저 싱크를 기록해 주세요."),
                ("시작과 끝 선택", "순서표에서 시작 동작, 끝 동작을 차례로 선택하거나 재생 막대 위에서 원하는 구간을 드래그하세요."),
                ("준비 시간과 범위 조정", "설정에서 ‘준비 카운트’를 바꾸고, 재생 막대의 주황색 양 끝을 움직여 범위를 다듬으세요. ‘구간 반복’을 다시 누르면 해제됩니다.")
            ], macTip:"⌘L 구간 반복 · Shift를 누른 채 재생 막대를 드래그해도 구간을 고를 수 있어요.",
            iPadTip:"구간 반복을 켠 뒤 재생 막대를 손가락으로 드래그하세요. 전체 반복·1곡 반복도 아래에서 선택할 수 있어요."),
        TutorialStep(label:"보관", symbol:"tray.and.arrow.down", title:"다음 연습도 바로 이어가요",
            summary:"자주 쓰는 곡과 순서표를 정리해 다음 수업을 준비하세요.",
            instructions:[
                ("즐겨찾기로 모으기", "파일 카드의 별을 누르면 즐겨찾기에 모입니다. 목록의 항목을 드래그해 순서도 바꿀 수 있어요."),
                ("순서표 백업하기", "설정의 ‘백업 내보내기…’로 라이브러리 정보를 보관하세요. 음원·영상 파일은 백업에 포함되지 않으니 별도로 보관해 주세요."),
                ("필요하면 다시 보기", "라이브러리 아래의 ‘사용 가이드’에서 언제든 이 안내를 다시 열 수 있어요. 이제 파일을 추가하고 연습을 시작해 보세요!")
            ], macTip:"파일 위치가 바뀌면 파일 메뉴의 ‘파일 다시 연결…’을 이용하세요. ‘목록에서 제외’는 원본 파일을 지우지 않아요.",
            iPadTip:"다른 기기로 옮긴 뒤에는 백업을 가져오고 음원·영상을 다시 연결해 주세요.")
    ]
}

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    private let accent = Color(red:0.12, green:0.30, blue:0.56)
    private var step: TutorialStep { TutorialStep.all[index] }

    var body: some View {
        VStack(spacing:0) {
            HStack {
                Label("처음 시작하기", systemImage:"book.closed.fill").font(.headline)
                Spacer()
                Button("닫기") { dismiss() }.keyboardShortcut(.cancelAction)
                    .help("사용 가이드에서 언제든 다시 볼 수 있어요")
            }.padding(20)
            Divider()
            HStack(spacing:4) {
                ForEach(TutorialStep.all.indices, id:\.self) { number in
                    Button { index = number } label: {
                        VStack(spacing:5) {
                            Text("\(number + 1)").font(.system(size:13, weight:.bold))
                                .frame(width:28,height:28)
                                .foregroundStyle(index == number ? Color.white : Color.primary)
                                .background(index == number ? accent : Color.secondary.opacity(0.12),in:Circle())
                            Text(TutorialStep.all[number].label).font(.caption)
                                .foregroundStyle(index == number ? Color.primary : Color.secondary)
                        }.frame(maxWidth:.infinity).padding(.vertical,4).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                        .accessibilityLabel("\(number + 1)단계, \(TutorialStep.all[number].label)")
                        .accessibilityValue(index == number ? "현재 단계" : "")
                }
            }.padding(.horizontal,20).padding(.vertical,10)
            ScrollView {
                VStack(alignment:.leading,spacing:20) {
                    HStack(alignment:.top,spacing:14) {
                        Image(systemName:step.symbol).font(.system(size:30,weight:.medium)).frame(width:40,height:40).accessibilityHidden(true)
                        VStack(alignment:.leading,spacing:8) {
                            Text(step.title).font(.title2.bold()).accessibilityAddTraits(.isHeader)
                            Text(step.summary).font(.callout).foregroundStyle(.white.opacity(0.9))
                        }
                        Spacer(minLength:0)
                    }.foregroundStyle(.white).padding(20).frame(maxWidth:.infinity,alignment:.leading)
                        .background(accent,in:RoundedRectangle(cornerRadius:16))
                    ForEach(step.instructions.indices, id:\.self) { number in
                        HStack(alignment:.top,spacing:12) {
                            Text("\(number + 1)").font(.caption.bold()).frame(width:24,height:24)
                                .background(Color.secondary.opacity(0.12),in:Circle()).accessibilityHidden(true)
                            VStack(alignment:.leading,spacing:5) {
                                Text(step.instructions[number].title).font(.system(size:15,weight:.semibold))
                                Text(step.instructions[number].detail).font(.system(size:13)).foregroundStyle(.secondary)
                                    .fixedSize(horizontal:false,vertical:true)
                            }
                        }
                    }
                    VStack(alignment:.leading,spacing:7) {
                        #if os(macOS)
                        Label("Mac에서 더 편하게",systemImage:"keyboard").font(.caption.bold())
                        Text(step.macTip).font(.caption).fixedSize(horizontal:false,vertical:true)
                        #else
                        Label("iPad에서 이렇게",systemImage:"hand.tap").font(.caption.bold())
                        Text(step.iPadTip).font(.caption).fixedSize(horizontal:false,vertical:true)
                        #endif
                    }.padding(14).frame(maxWidth:.infinity,alignment:.leading)
                        .background(Color.secondary.opacity(0.08),in:RoundedRectangle(cornerRadius:12))
                }.padding(.horizontal,24).padding(.top,6).padding(.bottom,24)
            }.id(index)
            Divider()
            HStack(spacing:12) {
                Button("이전") { index = max(0,index - 1) }.disabled(index == 0)
                Text("\(index + 1) / \(TutorialStep.all.count)").font(.caption).monospacedDigit().foregroundStyle(.secondary)
                Spacer()
                Button(index == TutorialStep.all.count - 1 ? "연습 시작하기" : "다음") {
                    if index == TutorialStep.all.count - 1 { dismiss() } else { index += 1 }
                }.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
            }.controlSize(.large).padding(20)
        }
        .background(.background)
        #if os(macOS)
        .frame(width:680,height:640)
        #else
        .frame(maxWidth:720,maxHeight:.infinity)
        #endif
    }
}
