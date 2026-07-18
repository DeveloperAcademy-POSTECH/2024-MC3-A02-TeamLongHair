# 상세 패널 전면 개편 설계 (Detail Panel Redesign)

- 날짜: 2026-07-18
- 브랜치: `feat/canvas-completion` (현재 작업 브랜치)
- 상태: 승인됨

## 배경

링크 노드를 클릭하면 나오는 우측 상세 패널이, 원래 **개발자 문서·코드 조각 수집기**용으로
설계돼 있다(개발자 테마 아이콘 10종 + 코드 스니펫 필드). 그러나 현재 앱의 컨셉은
**일반 웹서핑 탭 관리**다. 상세 패널을 이 컨셉에 맞게 전면 개편한다.

## 목표 / 비목표

**목표**
1. 일반 탭 관리자 정체성에 맞게 상세 패널 재설계 (리치 카드형)
2. URL에서 **파비콘·썸네일·제목·설명을 자동 취득**해 수동 입력을 최소화
3. 캔버스 노드의 개발자 아이콘을 **파비콘**으로 교체해 탭 식별성을 높임
4. 관리 필드 정리: 메모·태그·노드 컬러·저장 날짜 유지, 코드·수동 아이콘 제거

**비목표 (이번 범위 밖)**
- 검색/필터(태그·제목·메모·URL 대상) — 태그는 "표시·편집·필터 준비" 상태로만 둔다. 후속.
- 개발자 문서 수집 성격(코드 필드 등)의 유지

## 결정 사항

| 결정 | 선택 | 이유 |
|---|---|---|
| 앱 정체성 | 일반 탭 관리자 | 코드/개발자 아이콘 제거의 근거 |
| 자동 메타데이터 | 핵심 기능 | 파비콘·썸네일이 탭 식별에 가장 유용, 수동 입력 대체 |
| 패널 레이아웃 | 리치 카드형 | 자동 메타데이터를 가장 잘 살림 |
| 관리 필드 | 메모·태그·컬러·저장날짜 | 사용자 선택 |
| 설명 취득 | 베스트-에포트 HTML 파싱 | LinkPresentation은 description을 주지 않음 |

## 데이터 모델 변경 (`LinkModel.swift`의 `LinkDetail`)

- **제거**: `code: String`, `icon: Icon`
- **추가**:
  - `savedDate: Date` — 링크 캡처 시각(기본값 `.now`)
  - `pageDescription: String` — 자동 취득한 페이지 설명(기본 `""`)
  - `faviconData: Data?` — 파비콘 이미지 바이트(캐시)
  - `thumbnailData: Data?` — 페이지 미리보기 이미지 바이트(캐시)
- **유지**: `URL`, `title`, `tags: [String]`, `desc`(=메모), `color: IconColor`
- 마이그레이션: SwiftData 경량 마이그레이션(추가 필드는 자동, 제거 필드는 드롭).
  개인용이므로 마이그레이션 문제 시 스토어 리셋으로 폴백(문서에 명시).
- `Icon` enum(`IconEnums.swift`)은 `IconColor`만 남기고 `Icon`은 미사용이 되면 제거.
  단 `IconColor`는 노드 컬러에 계속 사용하므로 유지.

## 신규 컴포넌트: `LinkMetadataService`

- 위치: `Utils/LinkMetadataService.swift` (신규, pbxproj 등록)
- 인터페이스:
  ```swift
  struct FetchedLinkMetadata {
      var title: String?
      var faviconData: Data?
      var thumbnailData: Data?
      var description: String?
  }
  enum LinkMetadataService {
      static func fetch(urlString: String) async -> FetchedLinkMetadata?
      static func parseDescription(fromHTML html: String) -> String?   // 순수, 테스트 대상
      static func normalizedURL(from raw: String) -> URL?              // 순수, 테스트 대상
  }
  ```
- 동작:
  - `normalizedURL`: 스킴 없으면 `https://` 보정, 무효면 nil.
  - 제목·파비콘·썸네일: `LPMetadataProvider().startFetchingMetadata(for:)` → `LPLinkMetadata`
    - `metadata.title` → title
    - `metadata.iconProvider` → Data (favicon)
    - `metadata.imageProvider` → Data (thumbnail)
  - 설명: `URLSession`으로 HTML 일부를 받아 `og:description` 또는 `<meta name="description">`를
    `parseDescription`으로 추출(베스트-에포트, 실패 시 nil).
  - 타임아웃 설정, 모든 실패는 nil 필드로 폴백(throw 대신 옵셔널).

## 데이터 플로우

- **캡처 시** (`FloatingPanelView` 저장 경로):
  - `Link(detail:)` 생성 시 `savedDate = .now`.
  - 저장 직후 `Task { let m = await LinkMetadataService.fetch(...); 모델에 반영 }`.
    제목이 비어 있거나 기본값이면 취득 제목으로 채움. 파비콘·썸네일·설명 채우고 autosave.
- **상세 패널 열 때** (`DetailPanelView`):
  - `faviconData == nil` 등 메타데이터 미비 시 자동 1회 취득.
  - 헤더에 **새로고침 버튼** → 수동 재취득.
- **캔버스 노드** (`LinkNode`): `faviconData`가 있으면 그 이미지를, 없으면 `globe` SF 심볼을 표시.

## 상세 패널 레이아웃 (리치 카드)

`DetailPanelView`가 아래 서브뷰를 세로로 구성. 각 서브뷰는 단일 책임(파일 분리).

```
┌ HeaderView ────────────────────────┐
│ [ 썸네일 배너 (없으면 파비콘 큰 아이콘) ] │
│ (파비콘) 제목(TextField)   [열기][URL복사][새로고침] │
│ example.com (도메인)                │
├ URLRow ─────────────────────────────┤
│ URL   https://…  (TextField)        │
├ DescriptionView ────────────────────┤
│ 설명   자동 요약 (읽기 전용, 없으면 숨김) │
├ MemoView ───────────────────────────┤
│ 메모   [ 내 노트 TextEditor ]        │
├ TagView ────────────────────────────┤
│ 태그   #a #b  +                      │
├ ColorView ──────────────────────────┤
│ 컬러   ● ● ● ○ ●                     │
├ SavedDateRow ───────────────────────┤
│ 저장   2026-07-18                    │
└─────────────────────────────────────┘
```

- 서브뷰 목록: `LinkHeaderView`(썸네일/파비콘/제목/도메인/열기/복사/새로고침),
  `URLRow`, `LinkDescriptionView`, `MemoView`(기존 유지/정리), `TagView`(기존 로직 유지),
  `ColorView`(기존 유지), `SavedDateRow`.
- 기존 `LinkView`는 `LinkHeaderView` + `URLRow`로 대체. 기존 `CodeBlockView` 제거.
- 모든 편집은 모델에 직접 바인딩(이미 적용한 패턴)으로 즉시 저장.
- 하드코딩된 폭·색 정리(라이트/다크 적응 색만 사용).

## 캔버스 노드 변경 (`LinkNode.swift`)

- 개발자 아이콘(`link.detail.icon.imageName(...)`) → **파비콘**(`faviconData` → NSImage)
  또는 폴백 `globe` 심볼. 컬러 테두리·제목·태그·선택/드롭 하이라이트는 그대로.

## 오류 처리

- 메타데이터 취득 실패(네트워크 없음/무효 URL/타임아웃): 블로킹 없음, 기존 값 보존,
  플레이스홀더(globe, 썸네일 없음) 표시.
- 무효 URL: 열기/복사/취득 버튼 비활성.
- 설명 파싱 실패: 빈 값(설명 섹션 숨김).

## 테스트

- **로직 테스트**(swiftc, 기존 러너 확장):
  - `LinkMetadataService.parseDescription`: og:description / meta description / 없음 케이스.
  - `LinkMetadataService.normalizedURL`: 스킴 보정, 무효 입력.
- **수동 QA**: 실제 URL 취득(파비콘·썸네일·제목·설명), 노드 파비콘 표시, 마이그레이션 후
  기존 데이터 로드, 오프라인/무효 URL 폴백, 새로고침.

## 마일스톤

1. **M1 모델·서비스**: `LinkDetail` 필드 변경 + `LinkMetadataService`(+로직 테스트).
2. **M2 취득 배선**: 캡처 시 취득, 노드 파비콘 표시.
3. **M3 패널 UI**: 리치 카드 레이아웃 서브뷰 구성, 코드/아이콘 제거.
4. **M4 마무리**: 오류 폴백·새로고침·마이그레이션 확인, 전체 QA.
