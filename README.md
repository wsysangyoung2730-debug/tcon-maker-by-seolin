# TCON Maker by SEOLIN

서린태권도의 TCON 심사 등록용 사진 편집 iOS 앱입니다. 승인된 남색·흰색 디자인을 SwiftUI로 구현하고 기존 `TCON_MAKER_by_SEOLIN.html`의 얼굴 정렬, 배경 분리, 자르기 및 원본 저장 알고리즘을 앱 안에서 실행합니다.

## 실행

1. `develop` 브랜치를 체크아웃합니다.
2. `TCONMaker.xcodeproj`를 Xcode에서 엽니다.
3. `TCONMaker` 스킴과 iPhone 시뮬레이터를 선택하고 실행합니다.
4. 실기기에서는 Signing & Capabilities에서 개발 팀과 사용할 Bundle Identifier를 설정합니다.

- 최소 지원: iOS 17.0. iPhone 우선이며 iPad에서도 적응형 레이아웃으로 실행됩니다.
- 검증 도구: Xcode 27.0. 외부 패키지 설치나 API 키가 필요하지 않습니다.
- 프로젝트 파일 재생성: `python3 Scripts/generate_project.py`

```sh
xcodebuild -project TCONMaker.xcodeproj -scheme TCONMaker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
```

## 사용 흐름

사진 선택 또는 촬영 → 자동 맞춤 → 여러 장 확인 → 개별 편집 → 사진 앱·파일 앱·ZIP 저장 또는 공유.

사진 보관함과 파일 앱에서 여러 장을 추가할 수 있습니다. 사진 보관함은 한 번에 최대 30장씩 가져오며 추가 선택할 수 있습니다. HEIC와 EXIF 방향을 iOS에서 정규화합니다. 원본 사진은 덮어쓰지 않습니다.

## 주요 기능

- TCON 20×25mm, 증명사진 30×40mm, 여권사진 35×45mm 및 사용자 크기
- 얼굴 인식, 자동 방향·수평 보정, 얼굴/균형/상체 중심
- 상반신/얼굴 크게, 아래로 보일 범위, 머리 위 여백, 얼굴 크기
- 흰색·투명·원본 배경, 전체·개별 밝기
- 이동·확대·기울기 제스처와 슬라이더·숫자 입력, 좌우 90도 회전
- 격자·중앙선·눈높이·머리 위 여백 안내선 (저장 이미지에는 포함하지 않음)
- 전체 설정 적용 시 개별 수정 유지 또는 초기화
- 개별·선택·전체 저장, 중복 이름 처리, ZIP, iOS 공유
- JPG 용량 조절, 투명 PNG, 고화질 저장 모드

TCON 및 여권 프리셋은 원본 앱의 기본값을 옮긴 것입니다. 공식 규정 적합성이나 등록 승인을 판정하지 않습니다. 출시 전 제출 기관 안내와 대조해야 합니다.

## 구조와 개인정보

- `TCONMaker/Features`: 홈·일괄 작업·편집·저장·설정 화면
- `TCONMaker/Shared`: 재사용 UI 및 iOS 선택·공유 컨트롤
- `TCONMaker/App`: 앱 진입점·화면 이동·작업 상태
- `TCONMaker/Core/Models`: 사진 및 설정 데이터
- `TCONMaker/Core/Processing`: WKWebView의 로컬 사진 엔진 호출
- `TCONMaker/Core/Services`: 사진 가져오기·내보내기
- `TCONMaker/Resources/Engine/engine.html`: 원본 알고리즘·모델·ZIP 라이브러리와 네이티브 연결부
- `Scripts/native-bridge.js`: 엔진 연결부의 읽기 쉬운 소스. 수정 시 번들 HTML에도 같은 변경을 반영합니다.
- `Design/Approved`: 승인된 화면 시안
- `TCONMakerTests`, `TCONMakerUITests`: 파일·엔진 통합·화면 흐름 검증

WebView는 화면을 표시하는 용도가 아닌 기존 사진 알고리즘을 실행하는 로컬 처리 구성요소입니다. 사용자 인터페이스는 SwiftUI입니다. 사진과 얼굴 데이터는 외부 서버로 보내지 않습니다. 엔진의 외부 네트워크 접근은 CSP로 차단하며 임시 WebKit 저장소를 사용합니다.

현재 작업 사진은 메모리에 유지되며 앱을 종료하면 복구되지 않습니다. 완료한 결과를 저장해야 합니다. 설정만 UserDefaults에 남습니다. 공유용 임시 파일은 다음 앱 시작 시 정리합니다. 얼굴 인식 실패 시 수동 편집이 가능하며, 배경 분리 실패·용량 초과는 성공으로 숨기지 않고 저장 단계에서 알려줍니다.

원본 픽셀을 기준으로 크롭하지만 메모리 사용을 제한하기 위해 출력은 최대 1,600만 화소입니다. 원본과 같은 파일 용량을 보장하지 않으며, 고화질 모드는 용량 제한을 해제합니다. 투명 PNG는 JPG 용량 제한 대상이 아닙니다.

## Git 규칙

- 커밋: `[소문자 태그] 한글 명령조 제목` (50자 이하)
- 브랜치: `태그/#이슈번호-작업범위`
- `main`: 출시용 초기 기반. 이번 개발은 `develop`에 통합합니다.
- 작업 브랜치에 최신 `develop`을 먼저 병합하고 `develop` 대상으로 PR을 생성합니다.
- 작업 이슈: 브랜치 / 작업 목적 / 주요 작업 내용 / 완료 기준

세부 기능 대응은 [기능 대응표](Docs/FEATURE_PARITY.md), 검증 결과는 [검증 기록](Docs/VALIDATION.md), 배포 준비는 [출시 준비](Docs/RELEASE.md), 원본 라이브러리는 [출처](Docs/THIRD_PARTY.md)를 참고하세요.
