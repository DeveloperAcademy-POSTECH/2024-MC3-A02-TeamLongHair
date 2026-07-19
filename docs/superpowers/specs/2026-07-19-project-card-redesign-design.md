# 홈 프로젝트 카드 개선 — 파비콘 모자이크 커버 + 모노그램 폴백 설계

**날짜:** 2026-07-19
**상태:** 승인 대기(사용자 검토)

## 배경 / 목적

홈 갤러리의 프로젝트 카드는 커버가 `RoundedRectangle(.gray050).frame(height: 220)` — 내용과 무관한 **빈 회색 박스**라 로딩 스켈레톤처럼 보이고 공간만 차지한다. 정작 이 앱은 링크마다 파비콘을 저장하는데 카드에는 아무 내용 신호가 없다. 또 편집 시각 표기가 `"\(days)일 전 편집"`이라 오늘 편집한 프로젝트가 **"0일 전 편집"**으로 나온다.

이 작업은 카드 커버를 **내용에서 자동 생성한 미리보기**(프로젝트 링크들의 파비콘 모자이크, 없으면 제목 기반 모노그램)로 바꾸고, 제목·개수·상대 날짜 메타를 추가하며, 관련 quick win(날짜 카피, hover, 컨텍스트 메뉴 한글화, 빈 상태)을 함께 정리한다.

## 목표 / 비목표

**목표**
- 카드 커버: 파비콘이 있으면 **파비콘 모자이크**(host 중복 제거, 최대 9개), 없으면 **제목 색조 그라데이션 + 첫 글자 모노그램**.
- 카드 메타: 제목 + "N페이지 · M링크 · 상대 편집 날짜".
- 상대 날짜 카피 수정("오늘 편집" / "어제 편집" / "N일 전 편집").
- hover 상태, 컨텍스트 메뉴 한글화(이름 변경 / 삭제), 프로젝트 0개 빈 상태.
- 헤더 "프로젝트" 색을 `.primary`로.
- 순수 포맷팅 로직(색조·상대날짜·모노그램)은 프레임워크 의존 없는 파일에 두어 swiftc로 테스트.

**비목표(YAGNI)**
- 프로젝트 복제(중첩 딥카피), 실제 캔버스 스냅샷 커버, 정렬/검색/필터.
- 파비콘 캐싱 구조 변경(기존 `LinkDetail.faviconData` 그대로 사용).

## 아키텍처 개요

```
ProjectGallery (그리드)
  └─ ProjectCardView(project)                 ← 카드 1개(커버+제목+메타+hover+메뉴)
       ├─ ProjectCoverView(project)           ← 모자이크 or 모노그램 결정/렌더
       │     ├─ (파비콘 있음) FaviconMosaic    ← host-dedup 최대 9개 격자
       │     └─ (없음)        MonogramCover    ← stableHue 그라데이션 + 첫 글자
       └─ 메타: ProjectCardFormatting.relativeEditLabel + 개수
ProjectCardFormatting (순수, Foundation only)  ← stableHue / monogram / relativeEditLabel
ProjectCardData (파생 헬퍼)                     ← 프로젝트에서 파비콘/개수 추출(모델 접근)
```

## 컴포넌트 상세

### 1. ProjectCardFormatting (신규, `Home/ProjectCardFormatting.swift`, Foundation only → swiftc 테스트)

프레임워크 의존 없는 순수 포맷팅. `import Foundation`만.

```swift
enum ProjectCardFormatting {
    /// 제목을 결정적 해시로 0.0..<1.0 색조(hue)로. Swift 기본 Hasher는 실행마다 시드가
    /// 달라 색이 바뀌므로 쓰지 않고, 유니코드 스칼라 기반 FNV-1a 해시로 안정적으로 산출.
    static func stableHue(for title: String) -> Double {
        var hash: UInt64 = 0xcbf29ce484222325
        for scalar in title.unicodeScalars {
            hash ^= UInt64(scalar.value)
            hash = hash &* 0x100000001b3
        }
        return Double(hash % 360) / 360.0
    }

    /// 표시용 첫 글자(대문자). 공백/빈 문자열이면 "?".
    static func monogram(for title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "?" }
        return String(first).uppercased()
    }

    /// 상대 편집 라벨. now를 주입받아 테스트 가능하게 한다.
    /// 같은 날 → "오늘 편집", 하루 전 → "어제 편집", 그 외 → "N일 전 편집".
    /// (음수 방지: 미래 날짜는 "오늘 편집"으로 처리)
    static func relativeEditLabel(from date: Date, now: Date,
                                  calendar: Calendar = .current) -> String {
        let startOfDate = calendar.startOfDay(for: date)
        let startOfNow = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: startOfDate, to: startOfNow).day ?? 0
        switch days {
        case ..<1: return "오늘 편집"      // 0 또는 음수(미래)
        case 1:    return "어제 편집"
        default:   return "\(days)일 전 편집"
        }
    }
}
```

- `stableHue`는 재시작에도 같은 값(고정 알고리즘). 테스트에서 특정 문자열 → 특정 값 고정 검증.
- 날짜 라벨은 **달력 일자 경계**로 계산(자정 기준) → "0일 전" 대신 "오늘 편집".

### 2. ProjectCardData (신규, `Home/ProjectCardData.swift`, 모델 접근 헬퍼)

프로젝트에서 카드 렌더에 필요한 값을 뽑는다. `Project`/`Page`/`LinkDetail`(SwiftData) 접근이 있어 swiftc 순수 테스트 대상은 아니며, 로직은 얇게 유지.

```swift
import Foundation

extension Project {
    /// 프로젝트 전체 링크 수(모든 페이지의 링크 트리 평탄화 합).
    var totalLinkCount: Int {
        pages.reduce(0) { $0 + $1.allLinks.count }
    }

    /// 커버 모자이크용 파비콘 데이터. host 기준 중복 제거 후 정렬 순서로 최대 max개.
    /// host를 못 구하면 URL 문자열을 키로 사용(그래도 못 구하면 개별 취급).
    func mosaicFavicons(max: Int = 9) -> [Data] {
        var seenHosts = Set<String>()
        var result: [Data] = []
        for page in pages {
            for link in page.allLinks {
                guard let data = link.detail.faviconData else { continue }
                let key = URL(string: link.detail.URL)?.host ?? link.detail.URL
                if seenHosts.contains(key) { continue }
                seenHosts.insert(key)
                result.append(data)
                if result.count >= max { return result }
            }
        }
        return result
    }
}
```

- `Page.allLinks`(기존)로 트리를 평탄화. 정렬 순서를 그대로 따른다.

### 3. MonogramCover (신규, `Home/ProjectCoverView.swift` 내부 뷰)

제목 색조 기반 2톤 그라데이션 + 가운데 첫 글자.

- 색: `hue = ProjectCardFormatting.stableHue(for: title)`. `Color(hue:saturation:brightness:)` 두 개(밝기/채도 다르게)로 `LinearGradient`(대각선). 라이트/다크 모두에서 무난하도록 채도·밝기 고정값 사용.
- 첫 글자: `ProjectCardFormatting.monogram(for: title)`, 흰색, 큰 굵은 글씨, 중앙.

### 4. FaviconMosaic (신규, `Home/ProjectCoverView.swift` 내부 뷰)

`[Data]`(파비콘)를 받아 부드러운 배경 위 격자 타일로.

- 배경: 중립(예: `.gray050`) 또는 제목 색조의 아주 옅은 틴트.
- 레이아웃: 고정 열 수(예: 3열) `LazyVGrid`/`Grid`로 타일 배치. 타일은 라운드 사각형 + 파비콘 이미지(`NSImage(data:)`, `.aspectRatio(contentMode: .fit)`), 배경 흰색.
- 깨진 데이터(`NSImage(data:)==nil`)는 그 타일을 건너뛴다(globe 대체 없음 → 모자이크 깔끔 유지). 유효 파비콘이 0개가 되면 상위(ProjectCoverView)가 모노그램으로 폴백.
- 개수에 따라 자연스럽게 채움(1~9개 모두 보기 좋게, 커버 높이 고정).

### 5. ProjectCoverView (신규, `Home/ProjectCoverView.swift`)

```swift
struct ProjectCoverView: View {
    let project: Project
    var body: some View {
        let favicons = project.mosaicFavicons()
        // NSImage로 실제 디코드되는 파비콘만 유효로 취급
        let usable = favicons.filter { NSImage(data: $0) != nil }
        Group {
            if usable.isEmpty {
                MonogramCover(title: project.title)
            } else {
                FaviconMosaic(favicons: usable)
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

### 6. ProjectCardView + ProjectGallery 재구성 (`Home/ProjectGallery.swift`)

- 카드: `VStack(alignment:.leading)` — `ProjectCoverView(project:)` → 제목(`.primary`, size 16) → 메타 `Text("\(project.pages.count)페이지 · \(project.totalLinkCount)링크 · \(ProjectCardFormatting.relativeEditLabel(from: project.lastEditDate, now: Date()))")` (`.tertiary`, size 13).
- **hover**: `.onHover`로 상태 저장 → 테두리(옅은 강조)·`scaleEffect(1.02)`·shadow, `.animation`.
- **컨텍스트 메뉴 한글화**: "이름 변경" / "삭제"(destructive, `.keyboardShortcut(.delete)`).
- 인라인 이름 변경(TextField) 유지.
- 기존 `daysSinceLastEdit`는 삭제(포맷팅으로 대체).
- 그리드: `LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 20)], spacing: 24)` 정도로 폭·간격 일관화(값은 구현에서 미세조정).

### 7. 빈 상태 (`Home/ProjectGallery.swift` 또는 HomeView)

`ProjectGallery`가 `projects.isEmpty`일 때 그리드 대신 중앙 정렬 빈 상태를 표시한다: 아이콘 + "아직 프로젝트가 없어요" + 부제 + "새 프로젝트 생성" 버튼. 버튼은 새 프로젝트 생성 콜백을 받아 헤더 버튼과 동일하게 동작하도록, `ProjectGallery`에 `createProject: () -> Void` 콜백을 추가하고 HomeView가 `addProject(Project(title:))`를 넘긴다.

### 8. 헤더 다듬기 (`Home/HomeView.swift`)

`Text("프로젝트")`의 `.foregroundStyle(.secondary)` → `.primary`.

## 데이터 흐름

1. `@Query`로 정렬된 `projects`.
2. 각 카드: `ProjectCoverView`가 `project.mosaicFavicons()`를 뽑아 유효 파비콘이 있으면 모자이크, 없으면 `MonogramCover`(제목 색조).
3. 메타: `project.pages.count`, `project.totalLinkCount`, `relativeEditLabel(from:now:)`.
4. hover/컨텍스트 메뉴/이름 변경/삭제는 기존 콜백(openProject/deleteProject) 유지.

## 오류 처리

- 파비콘 데이터가 `NSImage`로 디코드 안 되면 해당 타일 제외; 모두 무효면 모노그램 폴백.
- 제목이 공백/빈 문자열 → 모노그램 "?", 색조는 빈 문자열 해시로 안정.
- 미래 `lastEditDate`(시계 편차) → "오늘 편집".
- 링크/페이지 0개 프로젝트 → 모노그램 + "N페이지 · 0링크".

## 테스트

**순수 로직(swiftc, `scripts/run_canvas_tests.sh` 확장)**
- `stableHue`: 같은 문자열 → 같은 값(결정성), 0.0 ≤ 값 < 1.0, 서로 다른 문자열은 (대개) 다른 값 — 특정 입력의 고정 기대값 몇 개.
- `monogram`: "MC3테스트"→"M", "일본취업"→"일", " abc"→"A"(trim), ""→"?", 이모지 시작→그 이모지.
- `relativeEditLabel`: 같은 날(now==date)→"오늘 편집", 하루 전→"어제 편집", 3일 전→"3일 전 편집", 미래→"오늘 편집". (고정 `Calendar`와 명시적 `now`/`date`로 결정적)

**수동 QA(SwiftUI/SwiftData/이미지 — swiftc 불가)**
- 파비콘 있는 프로젝트 → 모자이크(같은 사이트 중복 없이 최대 9개).
- 파비콘 없는 프로젝트 → 제목 색조 모노그램(프로젝트마다 다른 색, 재시작해도 동일).
- 메타 "N페이지 · M링크 · 오늘/어제/N일 전 편집" 정확.
- hover 강조, 컨텍스트 메뉴 한글(이름 변경/삭제), 인라인 이름 변경.
- 프로젝트 0개 → 빈 상태 + CTA.
- 라이트/다크 모두에서 커버 대비 양호.

## 파일 요약

| 파일 | 변경 |
|---|---|
| `Home/ProjectCardFormatting.swift` | 신규 — 순수 색조/모노그램/상대날짜(테스트 대상) |
| `Home/ProjectCardData.swift` | 신규 — Project 확장(totalLinkCount, mosaicFavicons) |
| `Home/ProjectCoverView.swift` | 신규 — ProjectCoverView + FaviconMosaic + MonogramCover |
| `Home/ProjectGallery.swift` | 수정 — 카드 재구성, hover, 메뉴 한글화, 빈 상태, 그리드 |
| `Home/HomeView.swift` | 수정 — 헤더 색, (빈 상태 분기 위치에 따라) |
| `scripts/run_canvas_tests.sh`, `CanvasLogicTests/main.swift` | 확장 — 포맷팅 테스트 |

**엔타이틀먼트/스키마 변경 없음.** 기존 `LinkDetail.faviconData`를 읽기만 한다.
