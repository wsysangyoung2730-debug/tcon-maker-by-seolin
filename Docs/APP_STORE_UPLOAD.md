> 최신 기록: [1.0.1 출시 기록](APP_STORE_1_0_1.md). 아래는 최초 1.0.0 업로드 당시 기록입니다.

# App Store Connect 업로드 기록 — 2026-10-13

## 앱과 빌드

- [App Store Connect](https://appstoreconnect.apple.com/apps/6822064133/distribution/ios/version/inflight)
- 앱 이름: TCON Maker by SEOLIN
- Apple ID: `6822064133`
- Bundle ID: `com.seolin.tconmaker`
- SKU: `tcon-maker-by-seolin-ios`
- 버전·빌드: `1.0.0 (1)`
- 대상: iPhone·iPad, 최소 iOS 17
- 소스: `d68783a` (이후 앱 소스 변경 없이 배포 설정과 기록만 추가)
- 배포 팀: `36545XSWN8`
- Apple Distribution 인증서로 서명, 업로드 성공 및 Apple 처리 후 출시 버전에 연결
- 업로드 식별자: `1d12adb9-38e1-41df-a08c-058393a3d727`
- 업로드 완료: 2026-10-13 04:39 KST
- Xcode 업로드 결과: `Uploaded TCONMaker`, `EXPORT SUCCEEDED`; 업로드 오류·경고 없음

## 저장한 출시 정보

- 한국어 앱 이름·부제·설명·프로모션 문구·키워드·지원 URL
- 사진 및 비디오 카테고리, 연령 등급 4+ (대한민국 전체)
- 타사 콘텐츠 없음, 로그인 필요 없음, 심사 메모와 사용자 제공 연락처
- 저작권 `2026 Sangyoung Woo`
- 무료 가격, 전체 175개 국가 및 지역, 공개 배포
- iPhone·iPad 대상. Apple Silicon Mac과 Apple Vision Pro 자동 배포는 해제
- 수동 출시: 심사 승인 후 별도 출시 동작 필요
- 개인정보 수집 없음: 사용자의 게시 동의를 받은 뒤 게시 완료

심사 연락처·인증서·프로비저닝 파일·계정 자격 증명은 저장소에 포함하지 않는다.

## 스크린샷

[최종 v4 자료](../Design/AppStore/README.md)에서 각 크기별 7장을 순서대로 등록했다.

| 슬롯 | 크기 | 수량 |
| --- | --- | --- |
| Dynamic Island iPhone 중형 | 1179 × 2556 | 7 |
| Dynamic Island iPhone 대형 | 1320 × 2868 | 7 |
| iPad 13형 | 2064 × 2752 | 7 |

순서: 표지 → 사진 준비 → 규격 → 편집 → 폴더 → 사진 선택 → 저장.
실제 앱 화면 기반이며 배터리·시간을 제외한 홍보 이미지다. 선택 사항인 별도 헤더·검색 결과 자산과 동영상 App Preview는 추가하지 않았다.

## 최종 상태

App Store Connect의 ‘심사에 추가’ 필수값 검사에서 다음 한 항목만 누락으로 표시되었다.

> 앱 개인정보에 개인정보 처리방침 URL을 입력해야 합니다.

개인정보처리방침 URL은 사용자 요청에 따라 공란이다. 현재 상태는 **제출 준비 중**이며 심사 제출·공개 출시는 하지 않았다. URL 입력 후 다시 제출 검사를 진행한다. 이 검사는 App Review의 실제 승인이나 [남은 수동 검증](RELEASE.md)을 대신하지 않는다.

## 재현 방법

기존 Xcode 로그인 계정과 배포 서명 권한이 필요하다. 다음 업로드에서는 새 빌드 번호를 사용한다. `ExportOptions-AppStore.plist`는 내보내기와 동시에 실제 업로드하므로 의도한 배포 시에만 실행한다.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project TCONMaker.xcodeproj -scheme TCONMaker \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath /private/tmp/TCONMaker-AppStore.xcarchive \
  -allowProvisioningUpdates archive

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -exportArchive -archivePath /private/tmp/TCONMaker-AppStore.xcarchive \
  -exportOptionsPlist Scripts/ExportOptions-AppStore.plist \
  -exportPath /private/tmp/TCONMaker-AppStore-Upload \
  -allowProvisioningUpdates
```

이번 업로드는 기존 검증을 반복하지 않고, 배포용 Archive·Apple 업로드 검사·스토어 필수값 검사만 수행했다.
