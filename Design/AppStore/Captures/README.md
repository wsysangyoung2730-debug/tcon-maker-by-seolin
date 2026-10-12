> 보존용 원본 캡처입니다. 최종 홍보 이미지와 업로드 안내는 [상위 폴더](../README.md)를 이용하세요. 아래 내용은 촬영 당시 기록입니다.

# App Store 한국어 스크린샷

실제 TCON Maker 1.0.0 (1) 화면을 촬영했다. 가상의 성인 예시 사진만 사용했으며 사용자 사진은 포함하지 않았다. 갤러리는 `index.html`을 브라우저에서 열면 된다. GitHub에서는 HTML 대신 각 PNG를 열어 확인할 수 있다.

| 폴더 | 크기 | 촬영 환경 |
| --- | --- | --- |
| iPhone-Medium-1179x2556 | 1179 × 2556 | iPhone 14 Pro / iOS 26.5, Apple Vision 흰색 배경 |
| iPhone-Large-1320x2868 | 1320 × 2868 | iPhone 18 Pro Max / iOS 27 시뮬레이터, 원본 배경 유지 |
| iPad-13-2064x2752 | 2064 × 2752 | iPad Pro 13형 / iOS 27 시뮬레이터, 원본 배경 유지 |

각 폴더에 8장, 총 24장의 불투명 PNG가 있다. [Apple 스크린샷 사양](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)에 맞는 크기이다. 실제 iPhone의 XCTest 캡처가 가로 1178픽셀로 반환되어 해당 묶음만 1179픽셀로 정규화했다. 세로 크기와 화면 구성은 유지했으며 UI·보정 결과를 합성하거나 다시 그리지 않았다. 시뮬레이터의 배경 분리 기능 제한을 숨기기 위한 합성 결과도 사용하지 않았다.

## 업로드

App Store Connect의 한국어 스크린샷 영역에서 기기 크기에 맞는 폴더의 PNG만 업로드한다. ZIP·HTML·manifest는 업로드하지 않는다. 지원하는 iPad용 이미지도 함께 등록한다. 실제 스토어 등록·배포는 수행하지 않았다.

추천 순서: `01-home` → `03-editor` → `02-folders` → `05-selection` → `06-export` → `04-background` → `07-settings` → `08-home-actions`. 홈 첫 화면과 스크롤 후 가져오기 영역을 별도로 담았다. 표시되는 규격과 배경 선택은 해당 촬영의 실제 설정이다.

## 재촬영 및 검증

`TCONMakerUITests/AppStoreCaptureTests`를 원하는 기기에서 실행한다. DEBUG 전용 테스트 사진함은 일반 앱 사진함과 분리된다. 실제 화면 전환·편집·폴더 생성·이동을 거쳐 첨부 파일을 보존한다. `xcresulttool export attachments`로 `store-` 첨부 파일을 추출할 수 있다. Release 앱에는 예시 자동 가져오기용 실행 인자가 포함되지 않는다.

`manifest.json`에 파일별 크기·투명도 여부·가로 1픽셀 정규화 여부·SHA-256을 기록했다. 새 빌드로 UI가 바뀌면 화면도 재촬영한다. 원본 XCResult는 개발 작업 환경에 보관하며 저장소에는 업로드용 이미지와 안내만 포함한다.
