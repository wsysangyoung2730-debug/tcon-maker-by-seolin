# TCON 앱 로고

- 도구: 내장 ImageGen, CLI 사용 없음
- 원본: `tcon-logo-source.png`
- 앱 에셋: `TCONLogo.imageset/tcon-logo.png`, `AppIcon.appiconset/icon.png` (1024×1024, 불투명 PNG)
- 출처: TCON 프레임·T 심벌은 생성 이미지, 우측 하단 서린태권도 표장은 사용자가 제공한 `seolin-logo-box.png`를 참고하여 합성
- 화면 오른쪽 하단의 서린태권도 표장은 기존 `SeolinLogo` 원본 에셋 사용

## 생성 프롬프트

Use case: logo-brand. Create one finished square 1024x1024 iOS app icon for a Korean taekwondo examination portrait cropping app named TCON. A minimal, distinctive, beautifully balanced white geometric capital T monogram inside four white portrait-cropping corner brackets, with the small bottom-right bracket in bright periwinkle blue. Main concept: a precisely aligned portrait frame and T for TCON; subtle martial arts discipline, modern and calm. Very simple thick consistent strokes, sharp clean vector-like edges, optically centered, generous safe margins (all marks within central 65% of canvas), legible at 32 pixels. Solid deep navy #202E78 full-bleed opaque square background all the way to all four edges. Flat 2D; no gradients, no texture, no shadows, no 3D, no device mockups, no outside rounded icon frame (iOS applies its own mask). Do not include words, text, a face, wings, or any existing organization emblem. Exactly one icon, no presentation board or variants. The main T must read immediately and the crop corners must be clearly separated from the T.

## 최종 서린 로고 합성 프롬프트

Precise compositing only. Image 1 is the FINISHED BASE ICON and must remain exactly as it is: same deep navy square, same white T, same three white crop corners, same complete full-size blue bottom-right crop corner in exactly the same position. DO NOT shrink, shorten, move, replace, or reshape any part of the base icon. Image 2 is a logo to place ON TOP as a small endorsement sticker. Composite the complete SEOLIN TAEKWONDO boxed logo from image 2 in the lower RIGHT, about 18% of full canvas width, centered near 83% horizontal and 85% vertical. It may naturally overlap a small part of the blue bottom-right corner like a sticker applied on top of an existing finished design. The underlying corner must retain its original geometry; only the overlay occludes it. Keep the exact logo proportions, navy outline, wing emblem, Korean 서린태권도 and English SEOLIN TAEKWONDO lettering. White backing inherent to the boxed logo, very subtle soft contact shadow only beneath badge if needed to feel attached, no other decoration. All pixels outside this small badge region should be preserved. No other redesign. Opaque square output. The user emphatically wants the original base unchanged with only the logo added on top.
