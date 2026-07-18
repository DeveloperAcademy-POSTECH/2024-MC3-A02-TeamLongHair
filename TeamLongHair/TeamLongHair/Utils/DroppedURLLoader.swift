//
//  DroppedURLLoader.swift
//  TeamLongHair
//
//  드롭된 NSItemProvider 배열에서 http/https URL을 비동기로 모아 메인 액터로 돌려준다.
//  캔버스 DropDelegate와 메뉴바 팝오버가 공유한다.
//

import Foundation

enum DroppedURLLoader {
    /// providers에서 .url을 우선 로드하고, 없으면 텍스트를 normalizedURL로 보정한다.
    /// http/https 스킴만 통과시키며, 완료 콜백은 항상 메인 액터에서 호출된다.
    static func load(from providers: [NSItemProvider], completion: @escaping ([URL]) -> Void) {
        let group = DispatchGroup()
        // provider 순서를 보존하기 위해 인덱스별 슬롯에 담는다.
        var slots = [URL?](repeating: nil, count: providers.count)
        // loadObject 완료 클로저는 provider별로 임의의 백그라운드 큐에서 동시에 실행될 수 있어
        // slots에 대한 쓰기를 잠금으로 직렬화한다.
        let lock = NSLock()

        for (index, provider) in providers.enumerated() {
            group.enter()
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    lock.lock()
                    slots[index] = url
                    lock.unlock()
                    group.leave()
                }
            } else if provider.canLoadObject(ofClass: String.self) {
                _ = provider.loadObject(ofClass: String.self) { string, _ in
                    if let string {
                        let normalized = LinkMetadataParsing.normalizedURL(from: string)
                        lock.lock()
                        slots[index] = normalized
                        lock.unlock()
                    }
                    group.leave()
                }
            } else {
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let urls = slots.compactMap { $0 }.filter { $0.scheme == "http" || $0.scheme == "https" }
            completion(urls)
        }
    }
}
