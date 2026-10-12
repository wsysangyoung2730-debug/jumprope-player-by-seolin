# JUMPROPE PLAYER by SEOLIN

macOS와 iPadOS를 위한 SwiftUI 기반 음악줄넘기 연습 앱.

음원·영상 재생, 동작 순서표와 타이밍 편집, 자동 스크롤, 카운트다운, 구간 반복 훈련을 지원합니다.

## 개발

- **macOS 우선**: macOS 14 이상, iPadOS 17 이상.
- `JumpRopePlayer.xcodeproj` → `JumpRopePlayer` 스킴 → My Mac 또는 iPad 시뮬레이터.
- 실제 기기 배포 시 Signing & Capabilities에서 개발 팀을 지정합니다.
- `swift test`: 플랫폼 독립 순서표·구간·데이터 테스트.
- Swift 파일 추가 후 `/usr/bin/python3 Scripts/generate_project.py`로 프로젝트를 갱신합니다.

## 구조

```text
App/
├── Application/       # 앱 진입점, 메뉴 동작, 기본 화면 구성
├── Features/          # Library · Practice · Editor · Playback · Settings
├── Services/          # 파일 접근·저장, 재생 세션, 백업 문서
├── Shared/Views/      # 공통 영상 표시
├── Platform/macOS/    # Mac 전용 휠 입력
├── Resources/         # 로고·에셋
├── Configuration/     # 권한·서명 설정
└── Development/       # Debug 화면 검증 데이터
Core/                  # 플랫폼 독립 데이터 모델·시간 계산·이전
Tests/                 # 핵심 테스트·실제 미디어 통합 검증
Scripts/               # 프로젝트 생성·빌드 검증·브라우저 내보내기
Docs/                  # 구조·Git 규칙·기능 대조표·검증 기록
Legacy/                # 비교용 원본 HTML
```

실제 폴더와 Xcode 탐색기는 같은 계층을 사용합니다. 파일 배치 기준과 추가 절차는 [프로젝트 구조](Docs/PROJECT_STRUCTURE.md)를 참고하세요.

## 사용 순서

처음 실행하면 6단계 튜토리얼이 열립니다. 닫은 뒤에도 라이브러리 하단 **사용 가이드**, Mac의 **도움말 → JUMPROPE PLAYER 사용 가이드…**에서 다시 볼 수 있습니다.

1. **폴더** 또는 **파일**로 음원·영상을 추가합니다.
2. 곡 선택 → **순서표 편집**에서 제목과 동작을 입력하거나 TXT를 불러옵니다.
3. 재생 중 **지금 싱크 찍기 / Enter**로 타이밍을 기록합니다.
4. 연습 무대와 보조 화면에 순서표·자동 스크롤·영상을 배치합니다.
5. **구간 반복**을 켜고 시작·끝 동작 또는 재생 막대 구간을 선택합니다.

Mac 단축키: Space 재생/정지, Enter 싱크 기록, ⌘Z 또는 Esc 싱크 취소, ↑/↓ 일시정지 동작 이동, Delete 목록 제외, ⌘O 파일 열기, ⇧⌘O 폴더 열기.

- [원본 기능 대조표](Docs/FEATURE_PARITY.md)
- [데이터 이전·백업](Docs/MIGRATION.md)
- [검증 결과와 제약](Docs/VALIDATION.md)
- [개발·Git 규칙](Docs/CONTRIBUTING.md)

`main`은 초기 상태를 유지하고 구현 결과는 `develop`에 통합합니다. 소스와 로고는 사용자가 제공한 HTML에서 옮겼습니다. 브라우저에서 저장한 데이터는 별도로 가져와야 합니다.

## App Store 배포

배포 설정·수정 사항·확인 결과와 제출 전 남은 항목은 [배포 점검 기록](Docs/APP_STORE_RELEASE.md)에 정리되어 있습니다.

앱스토어 이미지와 등록 문구는 [미리보기 안내](Marketing/AppStore/README.md), 사용자 지원은 [지원 안내](Docs/SUPPORT.md)를 참고하세요.
