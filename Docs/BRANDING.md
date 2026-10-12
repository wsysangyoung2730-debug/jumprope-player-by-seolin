# 앱 로고

헤드셋 형태의 줄넘기 고리·노란 손잡이·재생 버튼을 메인 심볼로 사용한다. 심볼은 남색 타일의 중앙을 기준으로 배치하고, 오른쪽 아래의 서린 도장은 얇은 흰 테두리와 부드러운 그림자를 가진 독립적인 스티커처럼 덧씌운다.

- 제작: 기본 내장 이미지 생성 도구로 기존 로고를 편집했다. 원본 서린 도장과 사용자가 제공한 겹침 배치 예시를 참고했다.
- 앱 내부 로고 원본: `App/Resources/Assets.xcassets/JumpRopeLogo.imageset/jumprope-player-logo.png`.
- Mac 대표 아이콘: `App/Resources/Assets.xcassets/AppIcon.appiconset/mac-512@2x.png`.
- iPad 대표 아이콘: `App/Resources/Assets.xcassets/AppIcon.appiconset/ios-marketing-1024@1x.png`.
- Mac과 앱 내부 로고는 투명 배경을 사용한다. 도장이 타일 위로 겹쳐진 외곽을 보존하도록 라이브러리 헤더에서 추가 모서리 마스크를 적용하지 않는다.
- iPad 아이콘은 불투명 정사각형이며 시스템 모서리 마스크에 도장이 잘리지 않도록 안쪽에 배치한다.
- 해상도별 아이콘은 이미지 생성 결과의 크기만 맞춰 저장한다.
- 아이콘 속 작은 서린 도장은 참조 이미지를 바탕으로 생성한 표현이다. 앱 하단 오른쪽은 제공된 원본 `SeolinBrandBox.imageset/seolin-logo-box.png`를 그대로 사용한다.
- 원본 서린 기본형은 `SeolinBrandBasic.imageset`에 보존한다.
- 앱 아이콘 설정은 `Scripts/generate_project.py`의 `ASSETCATALOG_COMPILER_APPICON_NAME`에서 관리한다.

## Mac·앱 로고 수정 프롬프트

```text
Use case: precise-object-edit / compositing.
Edit image 1, the existing JUMPROPE PLAYER Mac icon. Image 2 is a composition reference ONLY for how its lower-right Seolin stamp looks pasted on top. Image 3 is the original Seolin boxed logo for faithful brand details.
Make ONLY these small composition changes:
1. Move the entire white headset/jump-rope arch, both yellow handles, and white play triangle together so that the main symbol is centered horizontally AND vertically in the blue tile. Its center must be the blue tile's center, not the center of the leftover space next to the badge. Preserve the current symbol's shapes, proportions, scale, colors, highlights, and style. Do not turn it into conventional headphones with ear cushions.
2. Treat the Seolin stamp as an independent foreground sticker, laid OVER the finished centered icon, like the reference. Place it at the lower-right, with a crisp slim white sticker edge and subtle soft contact shadow to visibly lift it above the navy tile. It may slightly overlap the peripheral lower-right of the main artwork and extend just a little past the tile's lower/right edge, while remaining completely inside the image canvas. Do not move the main symbol away to make room. Do not merge or engrave the stamp into the background.
Keep the existing rich navy/blue gradient and rounded-square tile. Keep all Seolin lettering and winged SL emblem accurate using image 3. No additional text or new objects.
Square 1024x1024 final Mac icon, with genuine transparent alpha outside the icon and foreground stamp. No opaque white backdrop, no checkerboard drawing, no screenshot captions. Preserve the overall established look.
```

## iPad 아이콘 변환 프롬프트

```text
Use case: precise-object-edit / compositing.
Create the opaque iPad app-icon variant of the attached finished, centered Mac icon.
Keep the centered white headset/jump-rope arch, yellow handles, white play button, Seolin navy/blue palette, and the independent Seolin stamp sticker style. Preserve the main symbol's exact position and scale; do not push it aside to reserve space for branding.
Extend the existing navy/blue background seamlessly to ALL four edges of a square image. Remove only the transparent outer margin and rounded outer silhouette by filling them with the same blue background. This must be a completely opaque, full-bleed square.
Keep the Seolin stamp as a separate raised sticker over the lower-right artwork, with its slim white edge and soft shadow. Shift only this sticker slightly up/left as needed so its entire outer edge stays at least 11% of canvas width from the bottom and right edges, safe for the system's corner mask. A little overlap over the lower-right yellow handle is intentional, like a stamp laid on top.
Keep the logo lettering and winged SL mark faithful. No new text, no additional symbols, no outer frame, no white canvas, no transparency. Output one square 1024x1024 icon.
```
