# App Store 서명과 제출 파일

2026-10-13, 이슈 #26. Mac을 기본 제품으로 하고 iPad를 함께 제공한다.

## 설정과 완료 결과

- 개발자 팀 `36545XSWN8`, Bundle ID `com.seolin.jumpropeplayer`.
- 버전 **1.0.0**, 빌드 **1**. macOS 14 이상, iPadOS 17 이상.
- 로그인된 Xcode 계정의 기존 개발·배포·Mac 설치 인증서를 사용했다. 인증서를 새로 발급하거나 폐기하지 않았다. 개인 키는 키체인에만 보관한다.
- 프로젝트와 생성기에 자동 서명 팀을 설정했다. 플랫폼별 `App/Configuration/ExportOptions-*.plist`는 `app-store-connect`, `destination=export`로 로컬 파일만 만든다.
- Mac과 iPad의 Archive 및 Export가 모두 성공했다. Xcode가 명시적 Bundle ID에 맞는 Mac/iOS Team Store 프로비저닝 프로필을 연결했다.
- 자동 서명 아카이브 내부 앱은 Apple Development로 서명되어 있고, App Store 내보내기 과정에서 실제 제출 파일의 앱을 **Apple Distribution**으로 다시 서명했다. 이는 서로 다른 용도의 정상적인 Xcode 산출물이며, 아카이브를 열어 다시 배포할 수 있다.
- Mac PKG의 외부 설치 패키지는 **Mac Installer Distribution**으로 서명했다. 키체인과 `pkgutil`에서는 `3rd Party Mac Developer Installer`로 표시된다.

## 파일 위치

아래는 이슈 #26에서 처음 만든 빌드 1 기록이다. 현재 업로드한 제출 파일은 이슈 #28의 **`BuildArtifacts/AppStore-Connect-1.0.0-build2/`**이며, 바탕화면 `JUMPROPE_AppStore_제출용_1.0.0-build2` 바로가기로 열 수 있다. 상세 상태는 [App Store Connect 등록 기록](APP_STORE_UPLOAD.md)을 참고한다. 산출물 폴더는 Git에서 제외한다.

| 제품 | Xcode 아카이브 | 최종 App Store 제출 파일 |
| --- | --- | --- |
| Mac (Apple Silicon + Intel) | `macOS/JumpRopePlayer.xcarchive` | `macOS/Export/JumpRopePlayer.pkg` |
| iPad (arm64) | `iPadOS/JumpRopePlayer.xcarchive` | `iPadOS/Export/JumpRopePlayer.ipa` |

`Logs/`에는 플랫폼별 아카이브·내보내기 로그와 최종 패키지 확인 결과가 있다. dSYM은 각 아카이브에 보관한다. `SHA256SUMS.txt`는 최종 PKG·IPA의 체크섬이다.

## 최종 파일 확인

최종 PKG·IPA를 임시 위치에 풀어 **실제로 패키지에 들어 있는 앱**을 검사했다.

- `codesign --verify --deep --strict` 통과 및 Apple Distribution / 지정 팀 확인.
- Mac PKG 설치 서명과 Apple 인증서 체인 확인.
- Mac Universal (arm64, x86_64), iPad arm64와 iPad 전용 기기 설정 확인.
- 두 프로필 모두 정확한 Bundle ID·팀, App Store 배포 유형, 유효기간 확인. 기기 등록용/기업용 프로필이 아니다.
- 배포 앱의 디버깅 허용 권한 제외, Mac Sandbox·사용자 선택 파일·북마크 권한 확인.
- 버전 1.0.0 (1), 개인정보 매니페스트, 비면제 암호화 미사용 선언 확인.
- 촬영·데모 전용 명령어 제외, 패키지 실행 파일·아카이브 실행 파일·dSYM UUID 일치 확인.

이번 변경은 서명·내보내기 설정이며 앱 기능 코드는 바꾸지 않았다. 앞선 기능 검증을 반복하는 대신 두 플랫폼의 실제 아카이브·내보내기와 최종 서명 확인을 수행했다.

## 다음 빌드 재현

Xcode에서 같은 개발자 계정에 로그인한 Mac에서 실행한다. 인증서 개인 키 접근을 macOS가 요청하면 키체인 접근을 허용해야 한다. 계정 비밀번호나 인증서 개인 키를 저장소에 넣지 않는다.

```sh
Scripts/archive_app_store.sh
```

Mac만 생성하려면 `Scripts/archive_app_store.sh macOS`, iPad만 생성하려면 `Scripts/archive_app_store.sh iPadOS`를 사용한다. 두 번째 인수로 **새 출력 폴더**를 지정할 수 있다. 이미 존재하는 폴더에는 덮어쓰지 않는다. 기본 출력은 시간별 `BuildArtifacts/AppStore-*` 폴더다.

버전/빌드 번호는 `Scripts/generate_project.py`의 `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`에서 관리한다. 같은 버전·플랫폼으로 이미 업로드한 빌드를 다시 제출할 때는 빌드 번호를 올린다. 내보내기가 버전 번호를 자동 변경하지 않도록 설정했다.

## App Store Connect에서 이어서 할 일

1. Bundle ID가 같은 앱 레코드를 생성하거나 기존 레코드를 선택하고 macOS·iOS 플랫폼을 연결한다. iOS 빌드는 iPad 전용이다.
2. `.xcarchive`를 Xcode에서 열고 Distribute App → App Store Connect에서 서버 검증·업로드를 진행하거나, 최종 PKG·IPA를 Transporter로 업로드한다.
3. 처리 완료 후 플랫폼별 버전에서 빌드를 선택한다. 등록 정보·지원/정책 URL 등 제출 항목을 완료한 후 심사 요청한다.

이슈 #26은 제출 파일 준비까지 진행했다. 이후 이슈 #28에서 앱 레코드 등록, Mac·iPad 빌드 업로드, 한국어 이미지·문구와 개인정보처리방침 연결을 진행했다. 최신 결과는 [등록 기록](APP_STORE_UPLOAD.md)에 있다. 실제 심사 제출·출시는 진행하지 않았다. 실기기 확인 항목은 [배포 점검](APP_STORE_RELEASE.md)에 남아 있다.

## Apple 문서

- [배포 아카이브와 내보내기](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)
- [Mac 배포 서명](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac/)
- [Mac App Store 설치 패키지](https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution)
