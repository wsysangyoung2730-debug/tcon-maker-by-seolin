# 사진 엔진과 에셋 출처

배경 분리는 iOS 17 이상에 포함된 Apple Vision의 `VNGeneratePersonSegmentationRequest`를 사용한다. 사진은 기기 안에서 처리한다. 외부 모델 다운로드나 서버 전송은 없다. 기존 Robust Video Matting(GPL-3.0) 및 Selfie Segmentation의 가중치와 실행 코드는 제거했다. 저장된 편집은 유지하며 이전 분석 캐시는 Apple 결과로 다시 만든다.

얼굴 정렬·자르기·인코딩은 사용자가 제공한 HTML의 로컬 알고리즘을 사용한다. 아래 라이선스 전문은 앱 설정 → 앱 정보 → 라이선스 고지에서도 제공한다.

| 구성 요소 | 조건/공식 출처 |
| --- | --- |
| face-api 및 두 얼굴 모델 | [vladmandic/face-api MIT](https://github.com/vladmandic/face-api/blob/master/LICENSE), [원본 face-api.js MIT](https://github.com/justadudewhohacks/face-api.js/blob/master/LICENSE) |
| TensorFlow.js | [Apache-2.0](https://github.com/tensorflow/tfjs/blob/master/LICENSE) |
| JSZip 3.10.1 | [MIT / GPLv3 중 MIT 선택](https://github.com/Stuk/jszip/blob/main/LICENSE.markdown) |
| pako | [MIT](https://github.com/nodeca/pako/blob/master/LICENSE) |
| 인물 분리 | [Apple Vision](https://developer.apple.com/documentation/vision/vngeneratepersonsegmentationrequest) |

2026-10-13 번들의 두 얼굴 가중치가 공식 저장소 배포 파일과 바이트 단위로 일치함을 확인했다. 상세 SHA-256은 `face-model-provenance.json`에 기록했다. 이는 출처 확인 기록이며 별도의 법률 검토를 의미하지 않는다.

서린 로고와 승인된 디자인은 사용자가 제공했다. 기본 인물 사진은 생성된 가상의 성인으로 실제 수련생 사진을 포함하지 않는다(`DEMO_ASSET.txt`).

원본 HTML SHA-256: `bab147a5acadd75deaf6e09a5e41b8c40c3c5e5e2e057ecfc134755e2dd2c686`
