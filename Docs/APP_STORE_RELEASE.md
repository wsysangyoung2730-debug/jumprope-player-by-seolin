# App Store 배포 점검

점검일: 2026-10-13. macOS가 기본 제품이며 iPadOS를 함께 제공한다. 개인정보보호 사이트의 제작·검증은 요청에 따라 제외했다. **로컬 코드·패키지 점검 통과와 App Store 심사 승인은 다르다.** 실제 App Store Connect 업로드나 심사는 진행하지 않았다.

## 수정한 문제

| 범위 | 조치 |
| --- | --- |
| 배포 메타데이터 | 버전 1.0.0, 빌드 1, 저작권, 비면제 암호화 미사용 선언을 추가했다. Release dSYM을 생성한다. |
| 개인정보 API 선언 | `@AppStorage`의 기기 내 튜토리얼 설정에 대해 UserDefaults CA92.1을 선언했다. 추적·서버 수집은 없다. 두 플랫폼 번들에 PrivacyInfo.xcprivacy가 포함된다. |
| 백업 안정성 | 중복 ID, 깨진 참조, 비정상 숫자·화면 크기, 원격 URL, 폴더 밖 상대경로를 거부한다. 같은 검증을 앱 저장 파일에도 적용한다. 큰 백업·TXT 가져오기를 제한하고 백업 인코딩 실패를 빈 파일로 저장하지 않는다. |
| 재생 상태 | 로딩 작업 취소, 이전 파일의 지연 오류, 실패 파일의 재생 표시, 로딩 중 재시작, 백업 교체·마지막 곡 제거 시 상태 초기화를 수정했다. |
| 오디오 | iPad에서 인터럽트와 출력 장치 연결 해제 시 멈춘다. 백그라운드 진입 시 재생을 멈추며 백그라운드 재생을 홍보하지 않는다. |
| 파일 접근 | 만료 북마크를 갱신하고 일회성 TXT·백업 접근 권한을 해제한다. 이전 폴더 검색 결과가 복원한 라이브러리에 섞이지 않도록 한다. 폴더 기억 해제 후 하위 파일이 목록에서 사라지는 문제를 수정했다. |
| 입력·화면 | 텍스트 편집 중 앱 재생·삭제 단축키를 막고 목록 제외는 Cmd+Delete로 바꿨다. 좁은 iPad 창에서는 반복 버튼을 아이콘으로 줄인다. 자동 저장 문구를 '이 기기에 자동 저장'으로 바로잡았다. |
| 불필요한 쓰기 | 내용이 같은 라이브러리는 3초마다 다시 디스크에 쓰지 않는다. |

## 검증 근거

- 핵심 XCTest 16개 통과. 비정상 백업·극단 숫자·기존 백업 호환 회귀 검증 포함.
- 실제 AVPlayer 통합 확인 통과: WAV 재생, 싱크, 실행 취소, 구간 반복, 저장·복원, 원본 보존, 로딩 취소, 실패 파일, 폴더 기억 해제.
- macOS Release archive 성공: macOS 14+, arm64 + x86_64 Universal, 버전/빌드/카테고리/PrivacyInfo/dSYM 확인.
- iPadOS 기기용 Release archive 성공: iPadOS 17+, arm64, 기기 종류 iPad만([2]), 버전/빌드/PrivacyInfo/dSYM 확인.
- 생성된 Release 실행 파일에 `--qa-demo` 및 캡처용 데이터 생성 코드가 들어가지 않는다.
- App Sandbox 권한은 사용자가 고른 파일 읽기·쓰기 및 북마크로 제한된다. 별도 네트워크 클라이언트, 카메라, 마이크, 사진 보관함, 위치, 추적 권한을 요청하지 않는다.
- 앱 코드는 Apple 제공 프레임워크만 사용한다. 광고·분석·외부 SDK, 결제, 로그인, 원격 코드 다운로드가 없다. 외부 링크는 시스템 브라우저로 Instagram을 연다.
- 컴파일 오류 없음. AppIntents 미사용에 따른 메타데이터 추출 생략 경고만 있다.

초기 무서명 검증용 아카이브는 `BuildArtifacts/JumpRopePlayer-macOS.xcarchive`, `BuildArtifacts/JumpRopePlayer-iPadOS.xcarchive`에 보관한다. 후속 이슈 #26에서 계정 서명 아카이브와 Apple Distribution 서명 PKG·IPA를 **`BuildArtifacts/AppStore-1.0.0-build1/`**에 새로 만들었다. 제출에는 새 파일을 사용한다. [서명 설정·산출물·확인 결과](APP_STORE_SIGNING.md)를 참고한다.

## 제출 전에 남은 실제 확인

1. 개발자 팀·배포 인증서·Mac/iPad App Store 프로비저닝 연결과 최종 파일 서명 검증을 완료했다. App Store Connect에서 `com.seolin.jumpropeplayer`에 맞는 macOS·iOS 앱 레코드를 연결하고 계정의 계약 상태를 확인한다. 앱 레코드 등록·계약 상태는 아직 확인하지 않았다.
2. 준비된 서명 아카이브에서 Distribute App → App Store Connect → Validate/Upload를 실행하거나, 내보낸 PKG·IPA를 Transporter로 업로드한다. 로컬 서명·프로비저닝 검증과 Apple 서버 검증은 별개다. 같은 버전·플랫폼으로 이미 업로드한 빌드를 다시 제출하면 빌드 번호를 올린다.
3. 제공한 지원 문서 URL과 운영 연락처, 가격·판매 지역, 연령 등급 설문, 콘텐츠 권리, App Privacy(현재 구현은 데이터 수집 안 함)를 실제 운영 정보에 맞게 등록한다. 지원 연락처를 임의로 만들지 않았다. 개인정보보호 사이트/URL은 이번 범위 밖이다. 실제 정책 URL이 준비되면 App Store Connect와 앱 내 설정의 정책 링크도 연결해야 한다. 현재 앱에 외부 정책 링크를 임의로 넣지 않았다.
4. 실제 iPad의 파일 앱·iCloud Drive·외장 저장장치 재연결, Bluetooth/전화 인터럽트, 장시간 수업을 확인한다. Intel Mac은 Universal 컴파일만 확인했고 실기기 실행은 하지 않았다. 관련 후속 검증은 이슈 #9에 남아 있다.
5. MKV/WEBM/OGG 등은 확장자 가져오기를 허용하지만 코덱에 따라 재생되지 않을 수 있다. 스토어 문구에서 모든 형식 지원을 보장하지 않는다. 기본 권장 형식은 MP3/M4A/WAV, H.264·HEVC MP4/MOV다.

## App Review 메모 초안

이 앱은 사용자가 선택한 로컬 음원·영상과 동작 순서표를 연결해 줄넘기 수업을 연습하는 플레이어입니다. 로그인, 서버, 구독, 앱 내 구매가 없습니다.

검토 방법: 파일 추가로 MP3/M4A/WAV 또는 MP4/MOV 파일을 선택한 다음 순서표 편집에서 줄마다 동작을 입력하세요. 재생 중 '지금 싱크 찍기'를 눌러 각 동작 시간을 기록할 수 있습니다. '구간 반복'을 켜고 순서표에서 시작·끝 동작을 선택하면 준비 카운트 후 해당 구간을 반복합니다. 사이드바의 '사용 가이드'에서 전체 흐름을 볼 수 있습니다. 음원·영상 원본을 수정하거나 삭제하지 않습니다. 백업 JSON은 순서표·설정과 파일 연결 정보만 포함하며 미디어 자체를 포함하지 않습니다.

## 공식 기준

- [스크린샷 규격](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/): Mac 2880×1800, iPad 13인치 2064×2752 세로를 사용한다. PNG/sRGB/알파 없음.
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/): 2.1 완성도, 2.3.3 실제 사용 화면, 2.4.5 Mac Sandbox 등을 기준으로 점검했다.
- [Required reason API 선언](https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest): UserDefaults 사용 사유를 포함한다.

## 실제 화면 촬영 중 추가 수정

- Mac의 패널 너비를 측정한 값을 현재 이상적 너비로 다시 적용하던 순환을 끊었다. 이 순환은 집중 보기·편집창 전환 때 AppKit 제약 갱신 예외를 만들 수 있었다. 너비는 다음 실행을 위해 저장하고 현재 레이아웃의 기본 너비와 분리한다.
- 편집창을 열 때 보조 패널을 잠시 숨기고 사이드바 최소 너비를 고정해 글자가 세로로 찌그러지는 현상을 방지했다.
- 자동 스크롤 모드로 바꾸거나 창 크기를 변경하면, 일시정지 중에도 현재 동작으로 이동한다.
- iPad 집중 보기의 탐색 막대 배경을 명시해 제목 대비를 유지한다.

화면 수정 후 실제 Mac 앱에서 연습 → 편집 → 반복 → 집중 보기 → 가이드 전환과 정상 종료를 확인했다. iPad 13인치 시뮬레이터에서도 같은 5개 화면을 촬영했다. 캡처와 마케팅 소스는 별도 이슈 #22에 보관한다.
