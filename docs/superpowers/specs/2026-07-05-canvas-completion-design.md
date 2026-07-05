# 노드맵 캔버스 완성 설계 (Canvas Completion Design)

- 날짜: 2026-07-05
- 브랜치: `feat/canvas-completion` (base: `dev`)
- 상태: 승인됨

## 배경

브라우저 탭을 노드로 저장하고 탭 간 관계도를 그려주는 macOS 앱.
2024년 팀 프로젝트(MC3) 당시 피그마처럼 줌/팬이 되는 캔버스를 만들려다
SwiftUI `scaleEffect`/`ScrollView` 수동 계산의 한계로 미완성 상태로 중단됨.
이번 작업으로 캔버스를 완성하고 개인용으로 쓸 수 있는 수준까지 마무리한다.

## 목표 / 비목표

**목표**
1. NSScrollView 기반의 부드러운 줌/팬 캔버스 (핀치 줌, 두 손가락 팬, 관성)
2. 자동 트리 레이아웃 — 노드 위치는 알고리즘이 계산, 사용자는 드래그로 관계만 변경
3. 드래그&드롭 재부모화 — 검증 우선, 원자적 이동 (현재의 노드 유실 버그 제거)
4. 플로팅 패널의 브라우저 탭 자동 수집 (Safari / Chrome / Arc / Whale)

**비목표 (이번 범위 제외)**
- Mac App Store / 노터라이즈 배포 (개인용 완성 먼저)
- 노드 자유 배치(x,y 저장), 하이브리드 레이아웃
- 페이지 다중 관리 UI 개선 등 캔버스 외 기능 추가

## 결정 사항

| 결정 | 선택 | 이유 |
|---|---|---|
| 노드 배치 | 자동 트리 레이아웃 | 모델 변경 최소, 구현 난이도 최저, 마인드맵 UX에 적합 |
| 줌/팬 | NSScrollView (`allowsMagnification`) | 줌 중심점·관성·제스처 충돌을 OS가 해결 |
| 배포 | 개인용 완성 우선 | 샌드박스 제약 없이 AppleScript 사용 가능 |
| 베이스 브랜치 | `dev` | 캔버스 실험 커밋(fix/#42)을 제외한 깨끗한 통합 상태 |

## 아키텍처

```
CanvasView (재작성)
└─ ZoomableScrollView (NSViewRepresentable)   ← 줌/팬만 담당
   └─ NSHostingView
      └─ CanvasContentView (SwiftUI)          ← 그리기만 담당
         ├─ Canvas { }                        ← 연결선을 Path로 일괄 렌더
         └─ ForEach(nodes) { LinkNode().position(…) }

TreeLayout   (순수 함수)  Page.links 트리 → [Link.ID: CGPoint] + 전체 크기
CanvasViewModel           재부모화/이동/선택 로직 단일화
```

### ZoomableScrollView
- `NSScrollView` + `allowsMagnification = true`, 배율 0.25 ~ 3.0
- 콘텐츠는 `NSHostingView`로 SwiftUI 뷰 호스팅
- 줌 배율 표시를 위해 현재 magnification을 SwiftUI로 바인딩

### TreeLayout
- 입력: `[Link]` (페이지의 루트 링크 배열, 각 링크는 `subLinks` 재귀)
- 출력: 각 노드의 좌표 딕셔너리 + 콘텐츠 전체 크기
- 규칙 (tidy tree, 가로 방향 성장):
  - 깊이 d → x = d × (노드폭 + 가로간격)
  - 리프 노드마다 세로 한 행 차지, 부모의 y = 첫 자식의 y (기존 디자인 계승)
  - 형제 순서는 `sortIndex` 기준
- 상수는 `CanvasMetrics` 한 곳에 모음: 노드폭 244, 노드높이 118, 가로간격 32, 세로간격 등
  (현재 코드에 흩어진 매직넘버 정리)
- 순수 함수이므로 단위 테스트 대상

### CanvasContentView
- 크기 = TreeLayout이 계산한 콘텐츠 크기 + 패딩
- 연결선: SwiftUI `Canvas`에 둥근 ㄱ자(orthogonal) Path로 부모→자식 일괄 렌더
  (Rectangle 조각 수동 배치 제거 → 선 끊김 버그 구조적으로 소멸)
- 노드: 기존 `LinkNode` 뷰 재사용, `.position()`으로 배치
- 레이아웃 변경 시 노드 이동에 애니메이션 적용

### CanvasViewModel (재부모화 규칙)
- 드롭 검증을 **제거 전에** 수행. 통과 시에만 제거+삽입을 한 트랜잭션으로 실행
  (현재 버그: 검증 전 제거로 드롭 실패 시 노드 유실)
- 규칙:
  1. 자기 자신에게 드롭 금지
  2. 자기 자손에게 드롭 금지 (사이클 방지)
  3. 결과 깊이가 최대 깊이(3)를 초과하면 금지 — 기존 `checkIfThirdNode` 의도 계승.
     이동하는 서브트리의 높이까지 포함해 계산
- 드래그 페이로드: `Link.id.uuidString` (기존 방식 유지)
- 기존 `CanvasView`/`DrawNodes`의 중복 `moveLink` 제거

## 데이터 모델 변경

- `Link`에 `sortIndex: Int` 추가.
  SwiftData to-many 관계는 배열 순서를 보장하지 않으므로 형제 순서를 명시적으로 저장.
  읽을 때 `sortIndex`로 정렬, 삽입/이동 시 재부여.
- 그 외 모델 변경 없음 (자동 레이아웃이므로 좌표 저장 불필요).
- 마이그레이션: 기본값 0으로 추가(lightweight). 최초 로드 시 기존 배열 순서대로 재부여.

## 탭 자동 수집

- `BrowserTabReader` 유틸: `NSAppleScript`로 프론트모스트 브라우저의 활성 탭 URL/제목 조회
- 지원: Safari(`front document`), Chromium 계열(Chrome/Arc/Whale — `active tab of front window`)
- 프론트 앱의 번들 ID로 브라우저 판별 후 해당 스크립트 실행
- 플로팅 패널이 열릴 때 1회 실행하여 URL/제목 필드에 프리필
- 실패 시(미지원 브라우저·권한 거부·스크립트 오류) 빈 필드로 조용히 폴백 — 수동 입력이 안전망
- `Info.plist`에 `NSAppleEventsUsageDescription` 추가, 샌드박스는 비활성 유지

## 오류 처리

- 드롭 검증 실패: 이동 없음, 원상태 유지 (시각 피드백은 후속 과제)
- AppleScript 실패: 로그만 남기고 수동 입력 폴백
- SwiftData 저장 실패: 기존 패턴(`try?`) 유지하되 이동 로직에서는 실패 시 롤백

## 테스트

- **단위 테스트** (신규 테스트 타깃 추가)
  - `TreeLayout`: 단일 노드, 다중 루트, 깊은 트리, 형제 순서, 콘텐츠 크기
  - `CanvasViewModel`: 자손 드롭 거부, 자기 드롭 거부, 깊이 제한(서브트리 높이 포함), 이동 원자성, sortIndex 재부여
- **수동 QA**: 줌 중심점, 관성 팬, 드래그 프리뷰, 노드 100+개 성능, 탭 수집(브라우저별)

## 마일스톤

1. **M1 정적 캔버스**: ZoomableScrollView + TreeLayout + 연결선 렌더 — 기존 데이터가 부드럽게 줌/팬
2. **M2 인터랙션**: 드래그&드롭 재부모화 + 레이아웃 애니메이션 + 선택/인스펙터 연동 유지
3. **M3 탭 수집**: BrowserTabReader + 플로팅 패널 프리필
4. **M4 마무리**: sortIndex 마이그레이션 확인, 죽은 코드 정리(DrawNodes 등), 전체 흐름 QA

## 참고 (현재 코드의 알려진 문제)

- `CanvasView`/`DrawNodes`: 뷰가 레이아웃 계산 겸임, `moveLink` 중복, 검증 전 제거로 노드 유실 가능
- 기존 줌: 노드 크기(`sizeOfNode`) 변경 방식 — 진짜 캔버스 줌 아님 → 폐기
- `fix/#42-canvasView-UI`의 `TestCanvasView` 실험은 이 브랜치에 포함하지 않음 (stash에 보존)
