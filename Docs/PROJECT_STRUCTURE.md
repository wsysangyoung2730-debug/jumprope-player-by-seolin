# 프로젝트 구조

macOS를 기본 제품으로 개발하며 iPadOS는 같은 모델·서비스와 기능 화면을 공유한다. 화면 크기와 입력 방식의 차이는 해당 화면 또는 플랫폼 어댑터에서 처리한다.

## 폴더별 책임

| 경로 | 역할 |
| --- | --- |
| `App/Application` | 앱 시작, 환경 주입, 메뉴·가져오기 동작, 기본 화면 배치 |
| `App/Features/Library` | 파일·폴더 목록과 즐겨찾기 |
| `App/Features/Practice` | 연습 무대, 보조 화면, 동작 순서표 표시 |
| `App/Features/Editor` | 순서표 텍스트와 싱크 편집 |
| `App/Features/Playback` | 재생 버튼, 탐색 막대, 반복 구간 조작 |
| `App/Features/Settings` | 사용자 설정 화면 |
| `App/Services` | `LibraryStore`의 파일 접근·저장, `PracticeSession`의 재생 상태·편집 동작, `BackupDocument`의 파일 입출력 |
| `App/Shared/Views` | 기능 간 공유하는 영상 표시 UI와 Mac·iPad 뷰 연결 |
| `App/Platform/macOS` | AppKit을 사용하는 Mac 전용 입력 처리. iPad 빌드에서는 조건부 컴파일로 제외 |
| `App/Resources` | 이미지와 에셋 카탈로그 |
| `App/Configuration` | Mac 앱 샌드박스 등 서명·권한 설정 |
| `App/Development` | Debug 전용 예시 데이터. 일반 사용자 데이터와 분리 |
| `Core` | Foundation 기반 모델, 순서표·시간 계산, 백업 이전. SwiftUI·AVPlayer에 의존하지 않음 |
| `Tests/JumpRopeCoreTests` | Swift Package로 실행하는 핵심 회귀 테스트 |
| `Tests/Integration` | 실제 AVPlayer를 사용하는 독립 실행 검증. 앱 타깃에 포함하지 않음 |
| `Scripts` | Xcode 프로젝트 생성, 공통 검증, 브라우저 데이터 내보내기 |
| `Docs` | 개발 규칙, 기능 대조표, 데이터 이전, 검증 기록 |
| `Legacy` | 사용자가 제공한 원본 HTML. 기능 비교용이며 앱에 포함하지 않음 |
| `.github` | 이슈·PR 템플릿과 자동 빌드 검증 |

현재 소규모인 `Core`는 파일 단위로 구분한다. 기능이 커질 때 하위 폴더를 추가하며, 빈 폴더나 사용하지 않는 추상 계층을 미리 만들지 않는다.

## 파일 추가와 이동

1. 사용자 기능에 속하는 화면은 해당 `Features` 폴더에 둔다. 서로 다른 기능의 화면을 한 파일에 합치지 않는다.
2. 파일 접근·재생·저장 처리는 `Services`, 플랫폼에 독립적인 계산은 `Core`에 둔다.
3. 특정 OS에서만 사용하는 어댑터는 `Platform`에 두고 조건부 컴파일을 적용한다. 같은 책임을 가진 짧은 Mac·iPad 연결 코드는 공통 뷰에서 함께 관리할 수 있다.
4. 새 파일 추가 또는 경로 변경 후 `/usr/bin/python3 Scripts/generate_project.py`를 실행한다. 생성기는 디스크의 하위 폴더를 Xcode 그룹으로 반영한다.
5. `Scripts/verify.sh`로 핵심 테스트와 Mac·iPad 빌드를 확인한다. 생성된 `.xcodeproj`도 같은 커밋에 포함한다.

Xcode 앱 타깃은 `App`과 `Core`의 Swift 파일 및 에셋 카탈로그만 빌드한다. 테스트·문서·스크립트는 탐색기에 표시되지만 앱 코드나 번들에 포함되지 않는다. 핵심 테스트는 `Package.swift`에서 별도로 구성한다.

앱 기능·로고·권한을 추가하면 프로젝트 생성기의 빌드 입력과 설정도 함께 확인한다. `project.pbxproj`만 수동 수정하면 다음 생성 시 덮어써지므로 영구 설정 변경은 생성기에서 관리한다.

## 로컬 산출물

`.build`, `DerivedData`, `BuildArtifacts`와 Xcode 개인 설정은 Git에서 제외한다. `BuildArtifacts/JumpRopePlayer.app`은 로컬 확인용 앱이며 소스 프로젝트와 별개다.
