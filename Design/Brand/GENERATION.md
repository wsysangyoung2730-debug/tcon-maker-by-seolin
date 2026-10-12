# TCON 앱 로고

- 도구: 내장 ImageGen, CLI 사용 없음
- 원본: `tcon-logo-source.png`
- 앱 에셋: `TCONLogo.imageset/tcon-logo.png`, `AppIcon.appiconset/icon.png` (1024×1024, 불투명 PNG)
- 출처: TCON 프레임·T 심벌은 생성 이미지, 우측 하단 서린태권도 표장은 사용자가 제공한 `seolin-logo-box.png`를 참고하여 합성
- 화면 오른쪽 하단의 서린태권도 표장은 기존 `SeolinLogo` 원본 에셋 사용

## 생성 프롬프트

Use case: logo-brand. Create one finished square 1024x1024 iOS app icon for a Korean taekwondo examination portrait cropping app named TCON. A minimal, distinctive, beautifully balanced white geometric capital T monogram inside four white portrait-cropping corner brackets, with the small bottom-right bracket in bright periwinkle blue. Main concept: a precisely aligned portrait frame and T for TCON; subtle martial arts discipline, modern and calm. Very simple thick consistent strokes, sharp clean vector-like edges, optically centered, generous safe margins (all marks within central 65% of canvas), legible at 32 pixels. Solid deep navy #202E78 full-bleed opaque square background all the way to all four edges. Flat 2D; no gradients, no texture, no shadows, no 3D, no device mockups, no outside rounded icon frame (iOS applies its own mask). Do not include words, text, a face, wings, or any existing organization emblem. Exactly one icon, no presentation board or variants. The main T must read immediately and the crop corners must be clearly separated from the T.

## 서린 로고 합성 프롬프트

Edit image 1, the square navy TCON app icon. Image 2 is the exact supporting SEOLIN TAEKWONDO brand logo to insert. Keep the existing navy full-bleed background and white T/cropping-frame main symbol, its clean geometric style, colors and readable T. Add the complete unmodified image 2 logo as a small, crisp white-backed endorsement badge at the bottom RIGHT of the icon. Preserve its winged emblem, Korean 서린태권도 lettering and English lettering accurately; do not redraw, abbreviate or replace the uploaded logo. It should occupy approximately 19% of icon width, centered at 78% x, 81% y, with safe margins from both right and bottom edges for iOS corner masking. Adjust the main crop frame's bottom-right corner only if needed so it does not collide with or overlap the badge. The central T remains the dominant visual. Exactly one finished square app icon, not a mockup/presentation. No extra text, gradients, or shadows. Opaque square background right to all four edges. Output 1024x1024.

## 최종 여백 보정 프롬프트

Make a precise layout correction to this finished TCON icon. Keep every design element and all text unchanged. The SEOLIN endorsement badge is currently too close to the bottom-right edge for an iOS rounded icon mask. Move ONLY that complete small badge slightly up and left so its RIGHT edge is at 86% of canvas width and its BOTTOM edge is at 87% of canvas height (at least 13% margin below, 14% margin to right). Keep badge size around 16% of canvas width and preserve its lettering and wing symbol. If the blue crop corner collides, shorten only the blue bottom-right bracket to allow clean separation. Keep central T and other corners in their current positions, maintain navy opaque full-bleed square background, clean crisp edges. Exactly one icon, no rounded outer canvas, no presentation. No new elements or altered words.
