# 앱 로고

JUMPROPE PLAYER by SEOLIN의 줄넘기 연습과 음악 재생을 줄넘기 고리·재생 버튼으로 표현했다. 서린 남색을 바탕으로 노란 손잡이를 사용하고 오른쪽 아래에는 서린 브랜드 배지를 배치했다.

- 제작: 기본 내장 이미지 생성 도구. 아래 프롬프트로 생성 후 macOS용 투명 모서리 버전을 편집했다.
- 원본 앱 로고: `App/Resources/Assets.xcassets/JumpRopeLogo.imageset/jumprope-player-logo.png`.
- Mac 대표 아이콘: `App/Resources/Assets.xcassets/AppIcon.appiconset/mac-512@2x.png`.
- iPad 대표 아이콘: `App/Resources/Assets.xcassets/AppIcon.appiconset/ios-marketing-1024@1x.png`.
- 앱 하단 오른쪽의 서린 로고는 사용자가 제공한 `seolin-logo-box.png`를 그대로 사용한다. `SeolinBrandBox.imageset`에 보관하며 기본형도 `SeolinBrandBasic.imageset`에 보존했다.
- 아이콘의 작은 브랜드 배지는 이미지를 참고해 생성한 표현이며, 앱 하단 배지는 원본 파일이다.
- Mac 아이콘은 둥근 외곽 바깥을 투명 처리하고, iPad 아이콘은 불투명 정사각형이다. 각 해상도는 디자인 변경 없이 크기만 맞췄다.
- 앱 아이콘 설정은 `Scripts/generate_project.py`의 `ASSETCATALOG_COMPILER_APPICON_NAME`에서 관리한다.

## 앱 로고 생성 프롬프트

```text
Use case: logo-brand and compositing.
Create one polished, square 1024x1024 app icon for JUMPROPE PLAYER by SEOLIN, a Mac-first music jump-rope practice player.
Input images: the two supplied images are supporting brand assets. Image 2 is the SEOLIN TAEKWONDO boxed logo to place as a small maker's signature in the bottom-right of the new app icon. Preserve its winged SL emblem, blue/white colors, and lettering faithfully.
Main design: a bold, minimal geometric jump rope arch surrounding a large right-facing play triangle. The rope is clearly a sports jump rope, with two short warm yellow handles at its lower ends. Off-white rope and play triangle against a rich SEOLIN navy #1F2C73 full-bleed square background, with just a subtle tonal blue gradient for depth. Balanced confident geometry, thick clean strokes, generous space, elegant and legible at Dock icon sizes. Main symbol slightly above and left of center to leave breathing room for branding.
Place the supplied boxed Seolin logo as a small crisp white/navy badge in the bottom-right, about 19% of the canvas width, inset at least 7% from the right and bottom edges. Keep it distinct from the rope symbol without overlap.
Produce the finished icon artwork only: opaque edge-to-edge square background, no outer frame, no mockup, no extra typography or slogans, no photographic scene, no other symbols. The only lettering is already inside the supplied Seolin badge.
```

## Mac 아이콘 변환 프롬프트

```text
Use case: precise-object-edit / background-extraction.
Input image is the finished JUMPROPE PLAYER icon. Create its macOS Dock icon variant only.
Keep the existing jump-rope/play symbol, yellow handles, navy gradient, and lower-right Seolin badge unchanged in appearance and relative placement. Do not redesign, redraw, retype, or alter the lettering.
Make the square artwork a gently rounded square with smooth Apple-style corners (corner radius about 20% of the artwork width). Fit the complete artwork inside a centered tile covering 90% of a square 1024x1024 canvas. Keep all the Seolin badge fully visible.
Everything outside the rounded tile must be genuinely transparent alpha, including the small outer margin. No white or gray background, no checkerboard drawn into the artwork, no new elements. Output one finished transparent PNG.
```
