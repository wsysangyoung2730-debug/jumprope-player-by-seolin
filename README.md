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

- `App/`: SwiftUI 화면, AVPlayer, 파일 접근·저장.
- `Core/`: 데이터 모델과 순서표·시간 계산.
- `Tests/`: 핵심 동작 회귀 테스트.
- `Legacy/Original.html`: 이전 기능 비교용 원본. 앱 실행에 사용하지 않습니다.
- `Docs/`: Git 규칙, 기능 대조표, 검증 기록.
