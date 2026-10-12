# 기존 HTML 기능 대조표

기준: `Legacy/Original.html` (사용자가 제공한 2026-10-12 파일).
macOS가 기본 제품이며, iPadOS는 같은 기능을 터치와 창 크기에 맞춰 제공한다.
아래는 코드 이식 범위다. 빌드·자동 테스트·직접 화면 확인 여부는 VALIDATION.md에서 구분한다.

| 기존 기능 | 네이티브 구현 | 비고 |
| --- | --- | --- |
| 폴더 열기·다중 파일·하위 폴더 | LibraryStore.addFolder/addFiles, LibraryView | 시스템 선택창, 보안 범위 북마크 |
| 파일·폴더·텍스트 드롭 | RootView.importURLs | 텍스트는 선택 곡에 연결 |
| 경로·상위 폴더·곡 수·영상/순서표 표시 | LibraryView | 원본 구조와 곡 상태 유지 |
| 기본 이름·숫자 정렬·중복 방지 | LibraryStore, LibraryView | 경로 기반 중복 방지 |
| 즐겨찾기·즐겨찾기 재생 순서 | LibraryStore, PracticeSession.queue | 즐겨찾기 항목은 사이드바 상단 고정 |
| 곡·폴더 드래그 순서 및 저장 | LibraryView.reorder | 폴더별 사용자 순서 |
| 우클릭·더보기·목록 제외 | LibraryView.trackMenu | 파일과 순서표는 삭제하지 않음 |
| 여러 폴더 기억·다시 연결·기억 지우기 | LibraryStore | 파일 제공자의 재승인 필요 시 다시 선택 |
| 폴더 추가·삭제 자동 반영 | LibraryStore.rescan | 앱 활성 상태에서 3초 간격, 현재 곡 보존 |
| 재생·정지·이전·다음·더블클릭 재시작 | PracticeSession, TransportView | 이전 버튼 3초 규칙, 목록 끝 순환 |
| 일반 재생의 곡 끝 정지 | PracticeSession.ended | 반복 off는 다음 곡 자동 진행 없음 |
| 전체 반복·1곡 반복 | PracticeSession.ended/queue | 현재 폴더 또는 즐겨찾기 범위 |
| 재생 위치·시간 표시·클릭/드래그 탐색 | TimelineView | 동작 마커와 스냅 |
| 영상 클릭 재생·표시 위치 이동 | MediaSurface, StagePane | 두 화면 모두 영상이면 마지막 선택한 곳에 표시 |
| 영상 높이·패널 너비 조절 | StagePane, HSplitView | 화면 비율은 원본 왜곡 대신 유지 |
| 소리만 있는 영상 컨테이너 처리 | PracticeSession.hasVideo | 실제 영상 트랙 유무 판별 |
| 순서표 등록·제목·동작 텍스트·수정·삭제 | EditorView, Routine | 곡별 자동 저장, 삭제 확인 |
| 번호 정리·재정렬 시 시간 유지 | Routine.setText, EditorView | 편집 중 한글 조합을 강제로 변경하지 않음 |
| TXT·UTF-8 BOM·EUC-KR·첫 줄 제목 | TextImport | 테스트 포함 |
| 싱크 기록·Enter·대상 동작 표시 | PracticeSession.mark, EditorView | 0.1초 단위 기록 |
| 개별 다시 찍기·삭제·±0.1초 | PracticeSession.setTime | 동작 행에서 조작 |
| 실행 취소·Esc·전체 싱크 초기화 취소 | PracticeSession.undoEdit/clearTimes | ⌘Z도 지원, 미세 조정도 취소 가능 |
| 일정 간격 뒤 동작 자동 기록 | Routine.mark | 음원 길이 초과에서 중지 |
| 순서표 전체 표시·현재 동작 확대·지난 동작 | SequenceDisplay | 긴 목록은 스크롤로 접근 가능 |
| 중앙·보조 각각 전체/자동 스크롤/영상 | StagePane | iPad 좁은 창은 두 화면 전환 |
| 보조 글자 크기·왼쪽/가운데/오른쪽 정렬 | StagePane | 설정 저장 |
| 동작 클릭 시간 이동·일시정지 단계 이동 | PracticeSession.pick/step | 방향키·Mac 휠·iPad 스와이프 |
| 다음 동작 이름·잔여 초·대기·마지막 | StagePane.nextCue | 0/3/5/10초 카운트 설정 |
| 카운트 및 전환 알림음 | PracticeSession.tick/beep | 일반 알림음 켜기/끄기 |
| 반복 시작·끝 동작 선택·같은 동작 두 번 | PracticeSession.pickRange/span | 미설정 싱크는 이웃 동작 범위 |
| 순서표 마우스 드래그 반복 | SequenceDisplay | iPad는 시작·끝 터치로 대체 |
| 시간 드래그·Shift 드래그·선택 방식 혼합 | TimelineView | 순서표/시간 선택 혼합 |
| 반복 양 끝 조정·표시·해제 | TimelineView, PracticeSession | 최소 0.3초, AVPlayer 경계 관찰 |
| 반복 준비 0~30초·시작 표시·취소 | PracticeSession.startLoop | 일반 알림음과 별도 설정 추가 |
| 음원·영상에 같은 순서표 연결 | LibraryStore.link | 동시 재생 기능은 원본에도 없음 |
| 곡 전환 시 순서표 및 반복 상태 정리 | PracticeSession.select | 순서표 없는 곡에는 등록 안내 |
| 집중 보기·전체 화면 | RootView, Mac 표준 윈도우 | 패널 숨기기 + Mac 전체 화면 버튼 |
| 좁은 화면·다크 모드·움직임 줄이기 | SwiftUI, SequenceDisplay | 기기별 화면과 시스템 설정 적용 |
| Space/Enter/Esc/⌘Delete/방향키 | App Commands, RootView | 텍스트 입력은 시스템 편집 처리 |
| 안내·저장 실패·지원 안 되는 형식 | LibraryStore.notice, RootView | 재생 오류는 명시적으로 안내 |
| 서린 로고·Instagram 링크 | Assets.xcassets, LibraryView/SettingsView | 원본 로고 보존 |
| 기존 브라우저 데이터 이전 | export-browser-data.js, LegacyArchive | 미연결 순서표를 보관해 나중에 매칭 |
| 앱 백업·복원·파일 재연결 | BackupDocument, LibraryStore | 네이티브 추가 기능, 가져오기 전 복구 사본 |

## 플랫폼 차이

- 기존 blob → data URL 재시도는 브라우저 전용 우회다. 앱에서는 AVFoundation 오류를 표시한다.
- MP3/M4A/AAC/WAV/OGG/OGA/FLAC/WEBM/MP4/M4V/MOV/MKV 가져오기 확장자를 유지한다. 실제 재생은 OS의 컨테이너·코덱 지원에 달려 있다. 특히 MKV/WEBM/OGG와 오래된 코덱은 사용자 파일로 확인해야 하며 FFmpeg 등 별도 디코더는 포함하지 않았다.
- iPad 파일 제공자는 폴더 접근·외장 장치·백그라운드에 제약이 있다. 접근이 해제되면 같은 폴더를 다시 지정한다.
- 순서표 단위 공유는 공통 Routine ID로 구현한다. 한쪽 순서표 연결을 지워도 다른 쪽은 유지된다.
- 레이아웃은 픽셀 복제가 아닌 Mac 기본 사이드바·분할 패널·메뉴와 iPad 터치 화면으로 재구성했다.
