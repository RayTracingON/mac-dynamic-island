import XCTest
@testable import Mac灵动岛

@MainActor
final class ClipboardHubStoreTests: XCTestCase {

    /// A store backed by a throwaway defaults domain, so tests never touch the real history.
    private func makeStore() -> (ClipboardHubStore, UserDefaults) {
        let suiteName = "ClipboardHubStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        addTeardownBlock {
            UserDefaults().removePersistentDomain(forName: suiteName)
        }
        return (ClipboardHubStore(defaults: defaults), defaults)
    }

    private func addText(_ text: String, to store: ClipboardHubStore) {
        store.addItem(content: text, type: .text, sourceBundleID: nil, sourceAppName: nil, imageData: nil)
    }

    private func addImage(_ bytes: [UInt8], to store: ClipboardHubStore) {
        // ClipboardManager stores every image with the same placeholder content
        store.addItem(content: "[Image]", type: .image, sourceBundleID: nil, sourceAppName: nil, imageData: Data(bytes))
    }

    func testRepeatedTextIsStoredOnce() {
        let (store, _) = makeStore()
        addText("hello", to: store)
        addText("hello", to: store)
        XCTAssertEqual(store.items.map(\.content), ["hello"])
    }

    func testNewestItemComesFirst() {
        let (store, _) = makeStore()
        addText("first", to: store)
        addText("second", to: store)
        XCTAssertEqual(store.items.map(\.content), ["second", "first"])
    }

    func testDifferentImagesCopiedBackToBackAreBothKept() {
        let (store, _) = makeStore()
        addImage([1, 2, 3], to: store)
        addImage([4, 5, 6], to: store)
        XCTAssertEqual(store.items.count, 2)
        XCTAssertEqual(store.items.first?.imageData, Data([4, 5, 6]))
    }

    func testRepeatedImageIsStoredOnce() {
        let (store, _) = makeStore()
        addImage([1, 2, 3], to: store)
        addImage([1, 2, 3], to: store)
        XCTAssertEqual(store.items.count, 1)
    }

    func testMaxItemsDropsOldest() {
        let (store, _) = makeStore()
        store.maxItems = 3
        for text in ["a", "b", "c", "d"] {
            addText(text, to: store)
        }
        XCTAssertEqual(store.items.map(\.content), ["d", "c", "b"])
    }

    func testItemsSurviveReload() {
        let (store, defaults) = makeStore()
        addText("persisted", to: store)

        let reloaded = ClipboardHubStore(defaults: defaults)
        reloaded.loadFromDisk()
        XCTAssertEqual(reloaded.items.map(\.content), ["persisted"])
    }

    func testCopyingAnOlderItemAgainMovesItToTheFront() {
        let (store, _) = makeStore()
        for text in ["a", "b", "a"] {
            addText(text, to: store)
        }
        XCTAssertEqual(store.items.map(\.content), ["a", "b"])
    }

    func testLoweringMaxItemsTrimsTheHistory() {
        let (store, defaults) = makeStore()
        for text in ["a", "b", "c", "d"] {
            addText(text, to: store)
        }
        store.maxItems = 2
        XCTAssertEqual(store.items.map(\.content), ["d", "c"])

        let reloaded = ClipboardHubStore(defaults: defaults)
        reloaded.loadFromDisk()
        XCTAssertEqual(reloaded.items.map(\.content), ["d", "c"])
    }

    func testSettingsSurviveReload() {
        let (store, defaults) = makeStore()
        store.maxItems = 20
        store.ttlHours = 72

        let reloaded = ClipboardHubStore(defaults: defaults)
        XCTAssertEqual(reloaded.maxItems, 20)
        XCTAssertEqual(reloaded.ttlHours, 72)
    }

    func testItemsKeptForeverByDefault() {
        let (_, defaults) = makeStore()
        storeHistory([oldItem("last month", age: 30 * 24 * 3600)], in: defaults)

        let store = ClipboardHubStore(defaults: defaults)
        store.loadFromDisk()
        XCTAssertEqual(store.items.map(\.content), ["last month"])
    }

    func testExpiredItemsAreDroppedOnLoad() {
        let (store, defaults) = makeStore()
        store.ttlHours = 24
        storeHistory([oldItem("this morning", age: 3600), oldItem("two days ago", age: 2 * 24 * 3600)], in: defaults)

        let reloaded = ClipboardHubStore(defaults: defaults)
        reloaded.loadFromDisk()
        XCTAssertEqual(reloaded.items.map(\.content), ["this morning"])
    }

    func testShorterRetentionDropsOlderItems() {
        let (_, defaults) = makeStore()
        storeHistory([oldItem("this morning", age: 3600), oldItem("two days ago", age: 2 * 24 * 3600)], in: defaults)
        let store = ClipboardHubStore(defaults: defaults)
        store.loadFromDisk()

        store.ttlHours = 24
        XCTAssertEqual(store.items.map(\.content), ["this morning"])
    }

    private func oldItem(_ text: String, age: TimeInterval) -> IslandClipItem {
        IslandClipItem(content: text, type: .text, timestamp: Date(timeIntervalSinceNow: -age),
                       sourceBundleID: nil, sourceAppName: nil, imageData: nil)
    }

    private func storeHistory(_ items: [IslandClipItem], in defaults: UserDefaults) {
        defaults.set(try! JSONEncoder().encode(items), forKey: ClipboardHubStore.historyKey)
    }
}
