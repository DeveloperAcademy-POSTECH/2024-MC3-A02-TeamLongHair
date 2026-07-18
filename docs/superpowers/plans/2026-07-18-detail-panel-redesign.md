# 상세 패널 전면 개편 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 상세 패널을 일반 탭 관리자에 맞는 리치 카드로 재설계하고, URL에서 파비콘·썸네일·제목·설명을 자동 취득하며, 캔버스 노드 아이콘을 파비콘으로 교체한다.

**Architecture:** 순수 파싱 로직(`LinkMetadataParsing`)과 프레임워크 취득(`LinkMetadataService`, LinkPresentation+URLSession)을 분리한다. `LinkDetail` 모델에서 코드/개발자 아이콘을 제거하고 저장날짜·설명·파비콘·썸네일을 추가한다. 상세 패널은 단일 책임 서브뷰들의 조합으로 다시 구성한다.

**Tech Stack:** SwiftUI, SwiftData, LinkPresentation(`LPMetadataProvider`), URLSession. 순수 로직 테스트는 기존 `swiftc` 러너(`scripts/run_canvas_tests.sh`) 확장.

**Spec:** `docs/superpowers/specs/2026-07-18-detail-panel-redesign-design.md`

## Global Constraints

- 브랜치: `feat/canvas-completion` (현 작업 브랜치). 모든 커밋 이 브랜치에.
- macOS 배포 타깃 14.1, Xcode 26.2, objectVersion 56 pbxproj — 새 파일은 반드시 `scripts/xcodeproj_add.rb`로 등록, 삭제는 `scripts/xcodeproj_remove.rb`.
- 커밋 메시지 끝: `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`
- **빌드 확인** (이하 이 이름으로 지칭):
  ```bash
  cd /Users/damin/Desktop/AppleDeveloperAcademy/MC3/2024-MC3-A02-TeamLongHair && \
  xcodebuild -project TeamLongHair/TeamLongHair.xcodeproj -scheme TeamLongHair \
    -configuration Debug -derivedDataPath build build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -3
  ```
  기대: `** BUILD SUCCEEDED **`. 확인 후 `rm -rf build`.
- **로직 테스트**: `bash scripts/run_canvas_tests.sh` → 마지막 줄 `ALL TESTS PASSED`
- **기동 확인** (수동 QA용): `./build/Build/Products/Debug/TeamLongHair.app/Contents/MacOS/TeamLongHair` 백그라운드 실행 후 `pgrep -x TeamLongHair`로 생존 확인, `pkill -x TeamLongHair`로 종료. (이 환경에선 창이 안 뜨므로 크래시 여부만 확인, 실제 UI QA는 사용자 Xcode 실행에서)
- **모델 필드 정확값**: 제거 `code: String`, `icon: Icon` / 추가 `savedDate: Date`, `pageDescription: String`, `faviconData: Data?`, `thumbnailData: Data?` / 유지 `URL, title, tags: [String], desc, color: IconColor`
- **마이그레이션 폴백**: 추가 필드는 모두 기본값 보유(경량 마이그레이션). 만약 실행 시 마이그레이션 크래시가 나면 개발 데이터 리셋: `rm ~/Library/Application\ Support/default.store*`

---

### Task 1: LinkMetadataParsing — 순수 파싱 로직 (TDD)

URL 정규화와 HTML description 추출을 프레임워크 의존 없이 순수 함수로 만들어 swiftc로 테스트한다.

**Files:**
- Create: `TeamLongHair/TeamLongHair/Utils/LinkMetadataParsing.swift`
- Modify: `CanvasLogicTests/main.swift` (테스트 추가 — `if failures > 0` 앞에 삽입)
- Modify: `scripts/run_canvas_tests.sh` (컴파일 대상에 LinkMetadataParsing.swift 추가)

**Interfaces:**
- Produces:
  ```swift
  enum LinkMetadataParsing {
      static func normalizedURL(from raw: String) -> URL?
      static func parseDescription(fromHTML html: String) -> String?
  }
  ```

- [ ] **Step 1: 러너에 파일 추가**

`scripts/run_canvas_tests.sh`의 swiftc 인자 목록에 한 줄 추가(main.swift 앞):
```bash
  TeamLongHair/TeamLongHair/Project/Page/Canvas/TreeLayout.swift \
  TeamLongHair/TeamLongHair/Project/Page/Canvas/DropValidator.swift \
  TeamLongHair/TeamLongHair/Utils/LinkMetadataParsing.swift \
  CanvasLogicTests/main.swift
```

- [ ] **Step 2: 실패하는 테스트 작성**

`CanvasLogicTests/main.swift`의 `if failures > 0` 앞에 추가:
```swift
// MARK: - LinkMetadataParsing tests

expect(LinkMetadataParsing.normalizedURL(from: "example.com")?.absoluteString == "https://example.com",
       "스킴 없으면 https 보정")
expect(LinkMetadataParsing.normalizedURL(from: "https://a.com/x")?.absoluteString == "https://a.com/x",
       "기존 스킴 유지")
expect(LinkMetadataParsing.normalizedURL(from: "   ") == nil, "공백만이면 nil")
expect(LinkMetadataParsing.normalizedURL(from: "no scheme with spaces") == nil, "공백 포함 무효 URL은 nil")

expect(LinkMetadataParsing.parseDescription(fromHTML: "<meta property=\"og:description\" content=\"Hello world\">") == "Hello world",
       "og:description 추출")
expect(LinkMetadataParsing.parseDescription(fromHTML: "<meta name=\"description\" content=\"Desc here\">") == "Desc here",
       "meta description 추출")
expect(LinkMetadataParsing.parseDescription(fromHTML: "<meta name=\"description\" content=\"A &amp; B\">") == "A & B",
       "HTML 엔티티 디코드")
expect(LinkMetadataParsing.parseDescription(fromHTML: "<html><body>nothing</body></html>") == nil,
       "설명 없으면 nil")
```

- [ ] **Step 3: 실패 확인**

Run: `bash scripts/run_canvas_tests.sh`
Expected: 컴파일 에러 (`cannot find 'LinkMetadataParsing' in scope`)

- [ ] **Step 4: 구현**

`TeamLongHair/TeamLongHair/Utils/LinkMetadataParsing.swift`:
```swift
//
//  LinkMetadataParsing.swift
//  TeamLongHair
//
//  URL 정규화와 HTML description 추출(순수 함수). 프레임워크 의존 없음(swiftc 테스트 대상).
//

import Foundation

enum LinkMetadataParsing {
    /// 스킴이 없으면 https를 붙인다. host가 없거나 파싱 실패면 nil.
    static func normalizedURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let withScheme = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let url = URL(string: withScheme), url.host != nil else { return nil }
        return url
    }

    /// HTML에서 og:description 우선, 없으면 name="description"을 추출. 없으면 nil.
    static func parseDescription(fromHTML html: String) -> String? {
        if let d = metaContent(in: html, attribute: "property", value: "og:description") { return d }
        if let d = metaContent(in: html, attribute: "name", value: "description") { return d }
        return nil
    }

    private static func metaContent(in html: String, attribute: String, value: String) -> String? {
        let escaped = NSRegularExpression.escapedPattern(for: value)
        let pattern = "<meta[^>]*\\b\(attribute)\\s*=\\s*[\"']\(escaped)[\"'][^>]*>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range, in: html) else { return nil }
        let tag = String(html[range])
        guard let content = contentValue(in: tag) else { return nil }
        let decoded = decodeEntities(content).trimmingCharacters(in: .whitespacesAndNewlines)
        return decoded.isEmpty ? nil : decoded
    }

    private static func contentValue(in metaTag: String) -> String? {
        let pattern = "content\\s*=\\s*[\"']([^\"']*)[\"']"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: metaTag, range: NSRange(metaTag.startIndex..., in: metaTag)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: metaTag) else { return nil }
        return String(metaTag[range])
    }

    private static func decodeEntities(_ s: String) -> String {
        s.replacingOccurrences(of: "&amp;", with: "&")
         .replacingOccurrences(of: "&lt;", with: "<")
         .replacingOccurrences(of: "&gt;", with: ">")
         .replacingOccurrences(of: "&quot;", with: "\"")
         .replacingOccurrences(of: "&#39;", with: "'")
    }
}
```

- [ ] **Step 5: 테스트 통과 확인**

Run: `bash scripts/run_canvas_tests.sh`
Expected: `ALL TESTS PASSED`

- [ ] **Step 6: 앱 타깃 등록 + 빌드**

```bash
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj Utils LinkMetadataParsing.swift
```
**빌드 확인** (SUCCEEDED).

- [ ] **Step 7: 커밋**

```bash
git add TeamLongHair/TeamLongHair/Utils/LinkMetadataParsing.swift CanvasLogicTests/main.swift scripts/run_canvas_tests.sh TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj
git commit -m "feat: Add LinkMetadataParsing (URL normalize + HTML description) with tests

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: 모델 변경 + 빌드 유지 정리

`LinkDetail`에서 code/icon 제거, 새 필드 추가. 이로 인해 깨지는 참조(LinkNode 아이콘, LinkView 아이콘 피커, CodeBlockView)를 최소 수정해 빌드를 유지한다. (리치 카드 UI는 Task 5에서 구성.)

**Files:**
- Modify: `TeamLongHair/TeamLongHair/Model/LinkModel.swift`
- Modify: `TeamLongHair/TeamLongHair/Project/DetailPanel/IconEnums.swift` (Icon enum 제거)
- Modify: `TeamLongHair/TeamLongHair/Project/Page/Canvas/LinkNode.swift` (아이콘 → globe 플레이스홀더)
- Modify: `TeamLongHair/TeamLongHair/Project/DetailPanel/LinkView.swift` (아이콘 피커 제거)
- Modify: `TeamLongHair/TeamLongHair/Project/DetailPanel/DetailPanelView.swift` (CodeBlockView 제거)
- Delete: `TeamLongHair/TeamLongHair/Project/DetailPanel/CodeBlockView.swift`

**Interfaces:**
- Produces: `LinkDetail`에 `savedDate: Date`, `pageDescription: String`, `faviconData: Data?`, `thumbnailData: Data?` (그리고 code/icon 없음).

- [ ] **Step 1: LinkDetail 필드 교체**

`LinkModel.swift`의 `LinkDetail` 클래스를 다음으로 교체:
```swift
@Model
final class LinkDetail {
    var URL: String
    var title: String
    var tags: [String]
    var desc: String
    var color: IconColor
    var savedDate: Date = Date.now
    var pageDescription: String = ""
    var faviconData: Data? = nil
    var thumbnailData: Data? = nil

    init(URL: String, title: String) {
        self.URL = URL
        self.title = title
        self.tags = []
        self.desc = ""
        self.color = .gray
        self.savedDate = .now
    }
}
```

- [ ] **Step 2: Icon enum 제거**

`IconEnums.swift`에서 `Icon` enum 전체를 삭제하고 `IconColor`만 남긴다:
```swift
import SwiftUI

enum IconColor: String, CaseIterable, Codable {
    case gray, red, orange, yellow, green, sky, blue, purple, plum

    func returnColor() -> Color {
        switch self {
        case .gray: .gray100
        case .red: .nodeRed
        case .orange: .nodeOrange
        case .yellow: .nodeYellow
        case .green: .nodeGreen
        case .sky: .nodeSky
        case .blue: .nodeBlue
        case .purple: .nodePurple
        case .plum: .nodePlum
        }
    }
}
```

- [ ] **Step 3: LinkNode 아이콘 → globe 플레이스홀더**

`LinkNode.swift`에서 `Image(link.detail.icon.imageName(color: link.detail.color))` 줄(오버레이 내부)을 다음으로 교체 (Task 4에서 실제 파비콘으로 대체):
```swift
                        Image(systemName: "globe")
                            .resizable()
                            .foregroundStyle(link.detail.color.returnColor())
                            .frame(width: 20 * (sizeOfNode / 244), height: 20 * (sizeOfNode / 244))
```

- [ ] **Step 4: LinkView 아이콘 피커 제거**

`LinkView.swift`에서 아이콘 버튼+popover(showIconPicker, `Image(detail.icon...)`, `ForEach(Icon.allCases...)`)를 제거한다. 상단 HStack이 `[파비콘 자리]` 없이 제목 TextField + 열기 버튼만 남도록. 최소 수정본 — HStack 첫 요소(아이콘 Button 전체)와 `@State private var showIconPicker`, `.popover`, `.onTapGesture{ showIconPicker }`를 삭제:
```swift
struct LinkView: View {
    var link: Link
    var detail: LinkDetail

    var body: some View {
        VStack {
            HStack {
                TextField("제목", text: Binding(get: { detail.title }, set: { detail.title = $0 }))
                    .textFieldStyle(.plain)
                    .font(Font.custom("Pretendard", size: 16).weight(.bold))
                    .foregroundColor(.lbPrimary)
                Spacer()
                Button(action: { link.openInBrowser() }, label: {
                    Image(systemName: "safari")
                })
                .buttonStyle(PlainButtonStyle())
                .frame(width: 32, height: 32)
                .padding(12)
                .help("브라우저에서 열기")
            }

            TextField("URL", text: Binding(get: { detail.URL }, set: { detail.URL = $0 }))
                .font(Font.custom("Pretendard", size: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 5).stroke(.gray100, lineWidth: 1)
                }
                .foregroundColor(.gray900)
                .textFieldStyle(.roundedBorder)
                .padding(8)
        }
        .frame(width: 300, height: 118)
    }
}
```

- [ ] **Step 5: DetailPanelView에서 CodeBlockView 제거**

`DetailPanelView.swift`에서 CodeBlockView와 그 앞 Divider를 삭제:
```swift
            ScrollView {
                LinkView(link: link, detail: link.detail)

                Divider()

                TagView(detail: link.detail)

                Divider()

                ColorView(detail: link.detail)

                Divider()

                MemoView(detail: link.detail)
            }
```

- [ ] **Step 6: CodeBlockView 파일 삭제**

```bash
ruby scripts/xcodeproj_remove.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj CodeBlockView.swift
git rm TeamLongHair/TeamLongHair/Project/DetailPanel/CodeBlockView.swift
```

- [ ] **Step 7: 잔여 Icon/code 참조 확인 + 빌드**

```bash
grep -rn "\.icon\|detail.code\|CodeBlockView\|Icon\." TeamLongHair/TeamLongHair --include="*.swift" | grep -v "IconColor\|iconName\|systemImage\|statusIcon"
```
결과 없어야 함(있으면 제거). 그다음 **빌드 확인** (SUCCEEDED).

- [ ] **Step 8: 마이그레이션 기동 확인**

기존 스토어가 있는 상태로 앱을 실행해 마이그레이션 크래시가 없는지 확인:
```bash
./build/Build/Products/Debug/TeamLongHair.app/Contents/MacOS/TeamLongHair >/tmp/mig.log 2>&1 &
sleep 4; pgrep -x TeamLongHair >/dev/null && echo OK; pkill -x TeamLongHair
grep -iE "migration|fatal|crash" /tmp/mig.log | head
```
크래시 시(마이그레이션 실패) 개발 데이터 리셋: `rm ~/Library/Application\ Support/default.store*` 후 재확인. `rm -rf build`.

- [ ] **Step 9: 커밋**

```bash
git add -A
git commit -m "refactor: Drop code/dev-icon from LinkDetail; add savedDate/description/favicon/thumbnail

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: LinkMetadataService — 메타데이터 취득

URL에서 제목·파비콘·썸네일(LinkPresentation)과 설명(URLSession+파싱)을 비동기 취득한다. 아직 UI에 배선하지 않는다.

**Files:**
- Create: `TeamLongHair/TeamLongHair/Utils/LinkMetadataService.swift`

**Interfaces:**
- Consumes: `LinkMetadataParsing` (Task 1)
- Produces:
  ```swift
  struct FetchedLinkMetadata {
      var title: String?
      var faviconData: Data?
      var thumbnailData: Data?
      var description: String?
  }
  enum LinkMetadataService {
      static func fetch(urlString: String) async -> FetchedLinkMetadata?
  }
  ```

- [ ] **Step 1: 구현**

`TeamLongHair/TeamLongHair/Utils/LinkMetadataService.swift`:
```swift
//
//  LinkMetadataService.swift
//  TeamLongHair
//
//  URL에서 제목·파비콘·썸네일(LinkPresentation)과 설명(HTML 파싱)을 베스트-에포트로 취득.
//  모든 실패는 해당 필드 nil로 폴백한다(throw 없음).
//

import AppKit
import LinkPresentation

struct FetchedLinkMetadata {
    var title: String?
    var faviconData: Data?
    var thumbnailData: Data?
    var description: String?
}

enum LinkMetadataService {
    /// 무효 URL이면 nil. 그 외에는 취득 가능한 필드만 채운 구조체를 반환.
    static func fetch(urlString: String) async -> FetchedLinkMetadata? {
        guard let url = LinkMetadataParsing.normalizedURL(from: urlString) else { return nil }

        async let lp = fetchLinkPresentation(url)
        async let desc = fetchDescription(url)
        let (lpResult, description) = await (lp, desc)

        return FetchedLinkMetadata(
            title: lpResult.title,
            faviconData: lpResult.favicon,
            thumbnailData: lpResult.thumbnail,
            description: description
        )
    }

    private static func fetchLinkPresentation(_ url: URL) async
        -> (title: String?, favicon: Data?, thumbnail: Data?) {
        let metadata: LPLinkMetadata? = await withCheckedContinuation { continuation in
            let provider = LPMetadataProvider()
            provider.startFetchingMetadata(for: url) { metadata, _ in
                continuation.resume(returning: metadata)
            }
        }
        guard let metadata else { return (nil, nil, nil) }
        let favicon = await imageData(from: metadata.iconProvider)
        let thumbnail = await imageData(from: metadata.imageProvider)
        return (metadata.title, favicon, thumbnail)
    }

    private static func imageData(from provider: NSItemProvider?) async -> Data? {
        guard let provider else { return nil }
        return await withCheckedContinuation { continuation in
            _ = provider.loadObject(ofClass: NSImage.self) { object, _ in
                guard let image = object as? NSImage,
                      let tiff = image.tiffRepresentation,
                      let rep = NSBitmapImageRep(data: tiff),
                      let png = rep.representation(using: .png, properties: [:]) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: png)
            }
        }
    }

    private static func fetchDescription(_ url: URL) async -> String? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1)
        else { return nil }
        return LinkMetadataParsing.parseDescription(fromHTML: html)
    }
}
```

- [ ] **Step 2: 앱 타깃 등록 + 빌드**

```bash
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj Utils LinkMetadataService.swift
```
**빌드 확인** (SUCCEEDED).

- [ ] **Step 3: 커밋**

```bash
git add -A
git commit -m "feat: Add LinkMetadataService (favicon/thumbnail/title via LinkPresentation, description via HTML)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: 취득 배선 + 노드 파비콘

캡처 시와 상세 패널 열 때 메타데이터를 취득해 모델에 반영하고, 캔버스 노드가 파비콘을 표시하게 한다.

**Files:**
- Create: `TeamLongHair/TeamLongHair/Utils/LinkMetadataApply.swift` (취득→모델 반영 헬퍼)
- Modify: `TeamLongHair/TeamLongHair/FloatingPanel/FloatingPanelView.swift` (저장 후 취득)
- Modify: `TeamLongHair/TeamLongHair/Project/Page/Canvas/LinkNode.swift` (globe → 파비콘)

**Interfaces:**
- Consumes: `LinkMetadataService.fetch(urlString:)`, `FetchedLinkMetadata` (Task 3)
- Produces:
  ```swift
  @MainActor enum LinkMetadataApply {
      static func fetchAndApply(to detail: LinkDetail, force: Bool)
  }
  ```

- [ ] **Step 1: 반영 헬퍼 작성**

`TeamLongHair/TeamLongHair/Utils/LinkMetadataApply.swift`:
```swift
//
//  LinkMetadataApply.swift
//  TeamLongHair
//
//  LinkMetadataService로 취득한 값을 LinkDetail에 반영한다(메인 액터).
//

import Foundation

@MainActor
enum LinkMetadataApply {
    /// detail.URL로 메타데이터를 취득해 반영한다.
    /// force=false면 이미 파비콘이 있으면 건너뛴다(중복 취득 방지).
    static func fetchAndApply(to detail: LinkDetail, force: Bool = false) {
        if !force && detail.faviconData != nil { return }
        let urlString = detail.URL
        Task { @MainActor in
            guard let m = await LinkMetadataService.fetch(urlString: urlString) else { return }
            if let t = m.title, detail.title.trimmingCharacters(in: .whitespaces).isEmpty {
                detail.title = t
            }
            if let f = m.faviconData { detail.faviconData = f }
            if let th = m.thumbnailData { detail.thumbnailData = th }
            if let d = m.description { detail.pageDescription = d }
        }
    }
}
```

- [ ] **Step 2: 등록 + 빌드**

```bash
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj Utils LinkMetadataApply.swift
```
**빌드 확인**.

- [ ] **Step 3: 캡처 시 취득 배선**

`FloatingPanelView.swift`의 저장 로직(링크 생성 직후, `targetPage.links.append(newLink)` 뒤)에 추가:
```swift
                    targetPage.links.append(newLink)
                    LinkMetadataApply.fetchAndApply(to: newLinkDetail)
```

- [ ] **Step 4: 노드 파비콘 표시**

`LinkNode.swift`의 globe 플레이스홀더(Task 2에서 넣은 부분)를 파비콘 우선 표시로 교체:
```swift
                        Group {
                            if let data = link.detail.faviconData, let nsImage = NSImage(data: data) {
                                Image(nsImage: nsImage).resizable()
                            } else {
                                Image(systemName: "globe")
                                    .resizable()
                                    .foregroundStyle(link.detail.color.returnColor())
                            }
                        }
                        .frame(width: 20 * (sizeOfNode / 244), height: 20 * (sizeOfNode / 244))
```
`LinkNode.swift` 파일 상단에 `import AppKit`이 없으면 추가(`NSImage` 사용). 이미 `import SwiftUI`가 AppKit을 포함하지만 명시적으로 `import AppKit` 추가.

- [ ] **Step 5: 빌드 + 기동 확인**

**빌드 확인** (SUCCEEDED). 기동 확인(크래시 없음). `rm -rf build`.
**수동 QA(사용자)**: Chrome에서 ⌘⇧G로 링크 저장 → 잠시 후 캔버스 노드에 **파비콘**이 뜨는지, 무효/오프라인이면 globe 폴백인지.

- [ ] **Step 6: 커밋**

```bash
git add -A
git commit -m "feat: Fetch link metadata on capture and show favicon on canvas nodes

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 5: 리치 카드 상세 패널 UI

상세 패널을 리치 카드 레이아웃으로 재구성한다: 헤더(썸네일/파비콘/제목/도메인/열기/복사/새로고침), URL, 설명(자동), 메모, 태그, 컬러, 저장날짜.

**Files:**
- Create: `TeamLongHair/TeamLongHair/Project/DetailPanel/LinkHeaderView.swift`
- Create: `TeamLongHair/TeamLongHair/Project/DetailPanel/LinkDescriptionView.swift`
- Modify: `TeamLongHair/TeamLongHair/Project/DetailPanel/DetailPanelView.swift` (조립)
- Delete: `TeamLongHair/TeamLongHair/Project/DetailPanel/LinkView.swift` (헤더로 대체)

**Interfaces:**
- Consumes: `LinkMetadataApply.fetchAndApply(to:force:)`, `LinkMetadataParsing.normalizedURL(from:)`, `Link.openInBrowser()`
- Produces: `LinkHeaderView(link:detail:)`, `LinkDescriptionView(detail:)`

- [ ] **Step 1: LinkHeaderView 작성**

`TeamLongHair/TeamLongHair/Project/DetailPanel/LinkHeaderView.swift`:
```swift
//
//  LinkHeaderView.swift
//  TeamLongHair
//

import AppKit
import SwiftUI

struct LinkHeaderView: View {
    var link: Link
    var detail: LinkDetail

    private var domain: String {
        LinkMetadataParsing.normalizedURL(from: detail.URL)?.host ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 썸네일 배너(없으면 파비콘 큰 아이콘)
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(.bgSecondary)
                if let data = detail.thumbnailData, let img = NSImage(data: data) {
                    Image(nsImage: img)
                        .resizable().scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if let fav = detail.faviconData, let img = NSImage(data: fav) {
                    Image(nsImage: img).resizable().frame(width: 44, height: 44)
                } else {
                    Image(systemName: "globe").font(.system(size: 36)).foregroundStyle(.lbTertiary)
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .clipped()

            HStack(spacing: 8) {
                if let fav = detail.faviconData, let img = NSImage(data: fav) {
                    Image(nsImage: img).resizable().frame(width: 18, height: 18)
                }
                TextField("제목", text: Binding(get: { detail.title }, set: { detail.title = $0 }))
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.lbPrimary)
            }

            if !domain.isEmpty {
                Text(domain).font(.system(size: 12)).foregroundStyle(.lbTertiary)
            }

            HStack(spacing: 8) {
                Button { link.openInBrowser() } label: { Label("열기", systemImage: "safari") }
                Button {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(detail.URL, forType: .string)
                } label: { Label("URL 복사", systemImage: "doc.on.doc") }
                Spacer()
                Button { LinkMetadataApply.fetchAndApply(to: detail, force: true) } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("메타데이터 새로고침")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(12)
    }
}
```

- [ ] **Step 2: LinkDescriptionView 작성**

`TeamLongHair/TeamLongHair/Project/DetailPanel/LinkDescriptionView.swift`:
```swift
//
//  LinkDescriptionView.swift
//  TeamLongHair
//

import SwiftUI

/// 자동 취득한 페이지 설명(읽기 전용). 비어 있으면 아무것도 표시하지 않는다.
struct LinkDescriptionView: View {
    var detail: LinkDetail

    var body: some View {
        if !detail.pageDescription.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("설명")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.lbPrimary)
                Text(detail.pageDescription)
                    .font(.system(size: 12))
                    .foregroundStyle(.lbSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
        }
    }
}
```

- [ ] **Step 3: DetailPanelView 재조립 + 저장날짜 + 열 때 취득**

`DetailPanelView.swift`를 다음으로 교체:
```swift
import SwiftUI

struct DetailPanelView: View {
    @Binding var selectedLink: Link?

    var body: some View {
        if let link = selectedLink {
            ScrollView {
                VStack(spacing: 12) {
                    LinkHeaderView(link: link, detail: link.detail)
                    Divider()
                    LinkDescriptionView(detail: link.detail)
                    MemoView(detail: link.detail)
                    Divider()
                    TagView(detail: link.detail)
                    Divider()
                    ColorView(detail: link.detail)
                    Divider()
                    savedDateRow(link.detail)
                }
                .padding(.vertical, 12)
            }
            .frame(width: 300)
            .background(Color.bgPrimary)
            .onAppear {
                LinkMetadataApply.fetchAndApply(to: link.detail)
            }
            .onChange(of: link.id) {
                LinkMetadataApply.fetchAndApply(to: link.detail)
            }
        }
    }

    private func savedDateRow(_ detail: LinkDetail) -> some View {
        HStack {
            Text("저장").font(.system(size: 14, weight: .bold)).foregroundStyle(.lbPrimary)
            Spacer()
            Text(detail.savedDate.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 12)).foregroundStyle(.lbTertiary)
        }
        .padding(.horizontal, 12)
    }
}
```

- [ ] **Step 4: LinkView 삭제**

```bash
ruby scripts/xcodeproj_remove.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj LinkView.swift
git rm TeamLongHair/TeamLongHair/Project/DetailPanel/LinkView.swift
```

- [ ] **Step 5: 등록 + 빌드**

```bash
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj DetailPanel LinkHeaderView.swift
ruby scripts/xcodeproj_add.rb TeamLongHair/TeamLongHair.xcodeproj/project.pbxproj DetailPanel LinkDescriptionView.swift
```
**빌드 확인** (SUCCEEDED). 기동 확인. `rm -rf build`.
**수동 QA(사용자)**: 노드 선택 → 헤더 썸네일/파비콘/제목/도메인, 열기·복사·새로고침, 설명(있으면), 메모·태그·컬러·저장날짜가 링크마다 올바르게 로드/저장되는지.

- [ ] **Step 6: 커밋**

```bash
git add -A
git commit -m "feat: Rich card detail panel (header/thumbnail/description/saved date)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 6: 마무리 — 폴백·정리·전체 QA

**Files:**
- 정리 대상은 grep 결과에 따라

- [ ] **Step 1: 잔여 죽은 코드/참조 정리**

```bash
grep -rn "\.code\b\|\.icon\b\|Icon\.\|CodeBlockView\|LinkView(" TeamLongHair/TeamLongHair --include="*.swift" | grep -v "IconColor\|iconName\|systemImage\|statusIcon\|\.codable"
```
남은 참조가 있으면 제거. `MemoView`가 `Divider` 없이 헤더 설명 아래 자연스럽게 붙는지 레이아웃 확인(필요 시 spacing 조정).

- [ ] **Step 2: 로직 테스트 + 빌드 최종 확인**

**로직 테스트** (`ALL TESTS PASSED`) + **빌드 확인** (SUCCEEDED).

- [ ] **Step 3: 전체 흐름 수동 QA (사용자)**

1. Chrome/Safari에서 ⌘⇧G로 링크 여러 개 저장 → 노드에 파비콘 뜨는지
2. 노드 선택 → 상세 패널: 썸네일/제목/도메인/설명/메모/태그/컬러/저장날짜, 열기·복사·새로고침 동작
3. 오프라인/무효 URL → globe 폴백, 크래시 없음
4. 링크 전환 시 각 필드가 올바르게 갱신되는지(누출 없음)
5. 앱 재시작 후 파비콘·썸네일·설명이 유지되는지(캐시)
6. 기존(개편 전) 데이터가 마이그레이션 후 정상 로드되는지

- [ ] **Step 4: 커밋**

```bash
git add -A
git commit -m "chore: Clean up after detail panel redesign

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Self-Review 결과

- **스펙 커버리지**: 모델 변경(T2), LinkMetadataService(T1 파싱+T3 취득), 데이터 플로우(T4 캡처/열기), 리치 카드 UI(T5), 노드 파비콘(T4), 오류 폴백(T3 nil 폴백·T6 QA), 테스트(T1 로직), 마이그레이션(T2 확인) — 스펙 모든 섹션에 태스크 존재.
- **플레이스홀더**: 없음. 모든 코드 단계에 완전한 코드 포함.
- **타입 일관성**: `FetchedLinkMetadata`/`LinkMetadataService.fetch`(T3) ↔ `LinkMetadataApply`(T4) 사용 일치. `LinkMetadataParsing.normalizedURL/parseDescription`(T1) ↔ T3·T5 사용 일치. `LinkDetail` 새 필드(T2) ↔ T4·T5 사용 일치.
