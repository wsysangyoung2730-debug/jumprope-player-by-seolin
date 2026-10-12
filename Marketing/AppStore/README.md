# JUMPROPE PLAYER by SEOLIN · App Store 이미지

2026-10-13 제작. macOS 우선, iPadOS 별도 제공. 같은 바탕화면의 Blog Cover Maker / TCON App Store 예시에서 서린 블루, 큰 제목, 실제 앱 화면 중심의 구성을 참고했다.

## 업로드할 이미지

- `ko-KR/macOS`: 2880×1800 PNG 5장
- `ko-KR/iPadOS`: 2064×2752 PNG 5장 (13인치 iPad 세로)
- 모든 파일: sRGB, 불투명 RGB. App Store Connect에서 파일명 순서대로 등록한다.
- `Overview`는 검토용 모아보기로, App Store에 업로드하지 않는다.
- Apple 용어상 이번 결과는 **스크린샷 이미지**다. 'App Preview' 동영상은 포함하지 않는다.

| 순서 | 화면 | 소개 문구 |
| --- | --- | --- |
| 01 | 연습 무대와 라이브러리 | 음악과 동작을, 한눈에. |
| 02 | 순서표 싱크 편집 | 동작이 바뀌는 순간, 싱크를 톡. |
| 03 | 구간 반복 | 어려운 구간만, 한 번 더. |
| 04 | 자동 스크롤·집중 보기 | 리듬에 맞춰, 다음 동작으로. |
| 05 | 사용 가이드 | 첫 연습도, 차근차근 함께. |

## 원본과 재제작

`Source/Captures`는 실제 SwiftUI 앱 실행 화면이다. 가상의 동작 이름과 자체 생성 무음 WAV를 사용했으며 사용자 음악·영상·개인 파일을 노출하지 않는다. 기능 화면을 AI로 재생성하거나 조작 버튼을 이미지로 꾸며 넣지 않았다. 미리보기 바깥의 상단 영문 보조 문구·앱 로고와 하단 번호·서명은 제거하고 큰 한글 제목, 설명과 실제 앱 화면만 남겼다. 앱 화면 안의 로고와 UI는 원본 그대로 유지한다.

디자인은 편집 가능한 `Scripts/render_store_screenshots.swift`에서 관리한다. 배경·문구·프레임만 코드로 렌더링하고 원본 화면은 비율을 유지해 삽입한다.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift Scripts/render_store_screenshots.swift
python3 Scripts/verify_store_screenshots.py
```

캡처용 `App/Development/StoreCapture.swift`는 Debug에만 포함된다. 앱을 `--store-capture --store-page 0`으로 실행하면 별도 임시 라이브러리로 5장을 생성한다. `--store-page 1`~`5`는 개별 촬영이다. 결과는 캡처 앱의 Documents/StoreCaptures에 저장된다. 실제 화면이 나타난 후 촬영되므로 Mac 앱은 활성화되어 있어야 한다. 촬영용 Bundle ID는 `com.seolin.jumpropeplayer.storecapture`이며 본 앱 저장소와 분리된다. iPad는 iPad Pro 13인치 시뮬레이터의 세로 화면이다. 원본 화면이 바뀌면 다시 촬영한 뒤 렌더링한다.

## 등록 문구 초안

- 앱 이름: JUMPROPE PLAYER by SEOLIN
- 부제: 음악과 동작을 연결하는 줄넘기 연습
- 키워드: 줄넘기,음악줄넘기,순서표,구간반복,음악,영상,연습,싱크,태권도,수업,플레이어
- 카테고리: 음악 (배포 설정 기준)
- 지원 URL: https://github.com/wsysangyoung2730-debug/jumprope-player-by-seolin/blob/develop/Docs/SUPPORT.md

### 설명

음악에 맞춰, 한 동작씩. JUMPROPE PLAYER는 내 음원·영상과 동작 순서표를 연결하는 줄넘기 연습 앱입니다.

파일이나 폴더를 추가하고 자주 쓰는 곡을 즐겨찾기에 모아 보세요. 순서표 편집에서 동작을 입력한 뒤 음악이 바뀌는 순간 싱크를 기록할 수 있습니다. 0.1초 단위 미세 조정과 실행 취소로 시간을 맞추고, 어려운 구간은 시작·끝을 선택해 반복하세요.

전체 순서표, 자동 스크롤, 영상 보기와 다음 동작 안내를 수업에 맞게 선택할 수 있습니다. Mac에서는 키보드와 마우스로, iPad에서는 터치로 조작하세요. 처음 사용하는 분을 위한 6단계 가이드도 제공합니다.

순서표와 설정은 기기에 저장됩니다. JSON 백업 내보내기·가져오기를 지원하며, 로그인이나 앱 내 구매 없이 사용할 수 있습니다.

음원·영상 파일은 직접 준비해야 합니다. 권장 형식은 MP3/M4A/WAV 및 H.264·HEVC MP4/MOV이며, 실제 재생 가능 여부는 코덱에 따라 달라집니다. 백업에는 미디어 원본이 포함되지 않습니다. iPad에서는 앱이 백그라운드로 이동하면 재생이 멈춥니다.

## 배포 확인

코드 수정, Release 아카이브 확인 결과, 계정·실기기에서 남은 확인 사항은 `Docs/APP_STORE_RELEASE.md`를 참고한다. 개인정보보호 사이트는 이번 작업 범위에 포함하지 않는다. 지원 URL과 설명은 제공했지만 App Store Connect에는 아직 등록하지 않았다.

[Apple 공식 이미지 규격](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
