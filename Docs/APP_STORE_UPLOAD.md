# App Store Connect 등록과 업로드

작업일: 2026-10-13. 이슈 #28, 작업 브랜치 `setting/#28-appStoreConnect`.
macOS를 기본 제품으로 두고 iPadOS를 함께 제공하는 하나의 다중 플랫폼 앱으로 등록했다.
실제 심사 요청과 출시는 진행하지 않았다.

## 앱 레코드

| 항목 | 등록값 |
| --- | --- |
| 이름 | JUMPROPE PLAYER by SEOLIN |
| Apple ID | 6822076754 |
| Bundle ID | com.seolin.jumpropeplayer |
| SKU | seolin-jumprope-player |
| 기본 언어 | 한국어 |
| 버전 / 최종 빌드 | 1.0.0 / 2 |
| 기본 / 추가 카테고리 | 음악 / 스포츠 |
| 부제 | 음악과 동작을 연결하는 줄넘기 연습 |
| 저작권 | 2026 SEOLIN. All rights reserved. |
| 연령 등급 | 글로벌 4+, 대한민국 전체 |
| 가격 | 무료, 미국 기준 $0.00 / 대한민국 ₩0.00 |
| 배포 | 공개, 출시 후 175개 국가·지역 및 향후 추가 지역 |
| 출시 방식 | Mac·iPad 모두 수동 출시 |

- [macOS 버전](https://appstoreconnect.apple.com/apps/6822076754/distribution/macos/version/inflight)
- [iPadOS 버전](https://appstoreconnect.apple.com/apps/6822076754/distribution/ios/version/inflight)
- [공통 앱 정보](https://appstoreconnect.apple.com/apps/6822076754/distribution/info)
- [개인정보처리방침](https://seolin-apps-site.vercel.app/jumprope-player/privacy/)
- [사용 안내 및 지원](https://seolin-apps-site.vercel.app/jumprope-player/support/)

## 업로드와 코드 변경

빌드 1을 먼저 업로드했고, 사용자 제공 정책 사이트를 연결하기 위해 두 플랫폼을 빌드 2로 갱신했다. 최종 제출 초안에는 빌드 2를 사용한다. 이전 빌드 1은 TestFlight 이력에 남겨 둔다.

- 앱 설정에 정책·지원 링크와 지정 저작권을 추가했다. 링크는 시스템 브라우저로 연다.
- 생성 스크립트와 Xcode 프로젝트의 빌드 번호·저작권을 함께 갱신했다.
- Mac·iPad Release 아카이브, Apple Distribution 패키지 내보내기, 최종 PKG·IPA의 서명·프로필·권한·dSYM·개인정보 매니페스트 검증에 통과했다.
- Xcode에 로그인된 계정과 기존 배포 인증서를 사용했으며 새 계정·키·인증서는 만들지 않았다.
- 두 플랫폼 모두 업로드 로그에 `Upload succeeded.`와 `EXPORT SUCCEEDED`를 확인했다. TestFlight에서 1.0.0 (2)가 `제출 준비 완료`인 것을 확인했다. 업로드 날짜는 2026-10-13 오전 5:55 KST다.
- 작은 링크·설정 변경에 맞춰 두 플랫폼 Release 제작과 배포 패키지 확인만 진행했다. 기존 핵심 기능 테스트는 불필요하게 반복하지 않았다.

산출물: `BuildArtifacts/AppStore-Connect-1.0.0-build2/` (Git 제외).
바탕화면 바로가기: `JUMPROPE_AppStore_제출용_1.0.0-build2`.
`macOS/Export/JumpRopePlayer.pkg`, `iPadOS/Export/JumpRopePlayer.ipa`, 아카이브, `Logs/*-upload.log`, 검증 JSON 및 `SHA256SUMS.txt`가 들어 있다.

| 파일 | SHA-256 |
| --- | --- |
| Mac PKG | cc751d8de3cac72f0342484e30c849a3630b6a6f3dbbce71279fad97610bd00c |
| iPad IPA | d5d7393935ba4c64afaee7d9198952aeaaa613bb0e7d20ec4b6cf7d84e3df294 |

## 스토어 설정

- 한국어 설명·키워드·프로모션 문구와 각 플랫폼 스크린샷 5장을 저장했다. 문구·이미지 소스는 [마케팅 안내](../Marketing/AppStore/README.md)에 있다. Mac 2880×1800, iPad 13인치 2064×2752 PNG를 등록했다. 선택 사항인 헤더 자산이나 App Preview 동영상은 추가하지 않았다.
- 공통 개인정보처리방침 URL과 플랫폼별 지원 URL을 연결했다. 선택 사항인 개인정보 선택 URL·마케팅 URL은 비워 두었다.
- App Privacy는 `데이터가 수집되지 않음`이다. 앱은 로컬 처리만 하며 광고·분석·타사 SDK가 없다. Apple의 정확성·준수·갱신 의무 문구를 제시하고 사용자가 `동의하고 게시`라고 답한 후 게시했다.
- 연령 등급 설문은 앱이 실제 제공하는 콘텐츠·기능 기준으로 답했다. 앱 자체에는 의료 지침·도박·폭력·성적 콘텐츠·메시지·광고·UGC 배포가 없다. 어린이용 카테고리나 연령 재정의는 선택하지 않았다.
- 앱에 제3자 미디어를 번들로 배포하지 않는다. 사용자가 자신의 로컬 음악·영상을 선택하는 방식이며 콘텐츠 권한 항목은 제3자 콘텐츠 미포함으로 설정했다. 사용 안내에는 미디어 이용 권한 확인을 명시한다.
- 기존 madebySeolin 앱과 같은 심사 담당 연락처를 재사용하고 로그인 필요를 해제했다. 연락처·인증 정보는 저장소에 기록하지 않는다. 심사 메모에 파일 준비·순서표·싱크·반복·튜토리얼과 Mac 파일 권한 사유를 설명했다.
- Apple 표준 EULA, App Store 소프트웨어 세금 카테고리와 계정의 기존 DSA 비거래자 상태를 유지했다. 계정 계약·유료 계약 설정은 변경하지 않았다. 개인정보 답변 게시에 필요한 동의는 위에 기록한 사용자 승인에 따라 진행했다.
- Mac 전용 SwiftUI 앱을 제공하므로 iPad 앱의 Apple Silicon Mac 배포를 해제했다. 요청 대상이 아닌 Vision Pro 호환 배포도 해제했다. iPhone·Watch·VisionOS용 바이너리는 없다.
- 검증하지 않은 접근성 기능은 지원한다고 게시하지 않았다. 접근성 라벨, 이벤트·프로모션, 앱 내 구입·구독·Game Center는 이번 출시에서 사용하지 않는다.

## 제출 전 상태

Mac과 iPad 모두 빌드 1.0.0 (2)를 연결하고 `심사에 추가` 필수값 확인을 통과해 **심사 준비됨** 상태다. 별도 플랫폼의 제출 초안 2개를 만들었다. 두 초안의 `심사를 위해 제출` 버튼이 표시되며 실제 요청은 하지 않았다.

현재 필수 메타데이터 누락 오류는 없다. 마지막으로 사용할 두 플랫폼의 빌드·문구·이미지와 실기기 동작을 확인한 뒤, 출시를 진행할 때 각 초안의 `심사를 위해 제출`을 실행한다. 승인 후에는 수동 출시를 별도로 진행한다.

최종 필수값 확인은 App Store Connect가 받는 메타데이터의 준비 상태이며, Apple 심사 승인이나 모든 실기기 검증을 뜻하지 않는다. 실제 iPad의 파일 제공자·장시간 재생·인터럽트와 Intel Mac 실행은 [배포 점검](APP_STORE_RELEASE.md)의 후속 항목이다.

[Apple 공식 제출 절차](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app): `심사에 추가`는 제출 초안을 만들고, 별도 `심사를 위해 제출` 단계에서 실제 심사가 요청된다.
