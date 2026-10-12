# 검증 기록

2026-10-12, Apple Silicon Mac, Xcode 27.0 (27A266a).

## 통과

- macOS 14 이상 대상 Xcode Debug 빌드.
- iPadOS 17 이상 대상 시뮬레이터 Xcode Debug 빌드.
- XCTest 12개: 번호 재정렬과 싱크/ID 유지, 자동 간격·길이 제한, 미설정 동작의 반복 범위, 시간순 현재/다음 동작, UTF-8 BOM 및 EUC-KR, 유효 구간, JSON 저장 복원, 미연결 브라우저 순서표 보관, 나중에 연결한 영상의 편집 내용 보존, 잘못된 백업·미지원 버전 거부, 문자열 저장값 처리.
- 실제 AVPlayer에 30초 테스트 WAV를 넣는 통합 검증: 메타데이터, 재생 시간 진행, 싱크·자동 간격, 실행 취소, 2~3초 구간 반복, 저장 후 복원, 즐겨찾기, 원본 보존 목록 제외.
- Mac 앱 실행 및 순서표/자동 스크롤/편집 패널 표시. UI에서 6.0 → 6.1초 미세 조정, 실행 취소 6.0초 복귀, 재생 버튼 상태 전환 확인.
- iPad mini (A17 Pro), iPadOS 27 시뮬레이터 실행 및 세로 화면: 사이드바, 두 화면 전환, 순서표, 시간 마커, 재생·반복 조작부 표시 확인.
- Git 변경 공백 검사.

## 폴더 구조 정리 후 재검증 — 이슈 #10

- 기존 Swift 선언·동작 코드와 에셋·권한 파일의 보존을 원본과 비교 확인했다.
- Xcode 그룹에서 모든 파일 경로가 실제 파일로 연결되고, 앱 소스 19개가 중복 없이 빌드에 포함되는지 확인했다. 테스트·문서·스크립트는 앱 빌드에서 제외된다.
- 프로젝트 생성기를 연속 실행해 같은 결과가 생성되는지 확인했다.
- 핵심 테스트 12개, macOS 및 iPadOS 시뮬레이터 빌드가 통과했다.
- 새 `Tests/Integration` 경로로 통합 검증을 실행해 재생·싱크·실행 취소·구간 반복·저장 복원·즐겨찾기·원본 보존을 다시 확인했다.

## 추가 검증이 필요한 범위

- 사용자 실제 음원·영상, 특히 MKV/WEBM/OGG 및 서로 다른 코덱 조합. 가져오기 허용이 재생 보장을 뜻하지 않는다.
- 실제 iPad에서 파일 앱/iCloud Drive/외장 저장장치의 접근 재승인, 오디오 인터럽트, 장시간 수업, Bluetooth 출력 지연.
- 사용자 브라우저에 남아 있는 실제 순서표 데이터의 전체 이전. 자동 테스트는 합성 데이터로 검증했다.
- iPad의 모든 크기·가로·멀티태스킹 조합 및 VoiceOver 전체 사용 흐름.
- 배포용 개발 팀 서명·공증·App Store 심사. 현재는 로컬 개발 빌드다.

## 재현

`Scripts/verify.sh`는 핵심 테스트와 Mac·iPad 빌드를 실행한다. Xcode의 경로가 다르면 DEVELOPER_DIR을 설정한다. CI도 같은 스크립트를 사용한다.

실제 재생 통합 확인:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swiftc -parse-as-library Core/*.swift App/Services/LibraryStore.swift App/Services/PracticeSession.swift Tests/Integration/SmokeTest.swift -o /tmp/jrp-smoke
/tmp/jrp-smoke '/경로/30초-테스트.wav'
```

Debug 빌드를 `--qa-demo` 인수로 실행하면 별도의 임시 라이브러리와 무음 WAV를 만들어 화면을 확인한다. 일반 사용자 데이터와 분리되며 Release 빌드에는 이 생성 코드가 포함되지 않는다. 일반 실행에서는 예시 순서표를 넣지 않는다.

## App Store 준비 — 이슈 #20, #22 (2026-10-13)

핵심 테스트 16개와 AVPlayer 통합 확인, macOS Universal 및 iPadOS 기기용 Release 아카이브가 통과했다. 실제 화면 촬영 중 확인한 Mac 편집창/집중 보기 전환 오류와 자동 스크롤 위치, iPad 제목 대비도 수정했다. Mac 5단계 화면 전환과 정상 종료, iPad 13인치 시뮬레이터의 5개 화면, PNG 10장의 규격·sRGB·알파 없음 상태를 확인했다.

자세한 수정 내역과 계정·실기기에서 남은 검증은 [배포 점검 기록](APP_STORE_RELEASE.md)에 기록했다. App Store Connect 업로드나 심사 통과를 의미하지 않는다.
