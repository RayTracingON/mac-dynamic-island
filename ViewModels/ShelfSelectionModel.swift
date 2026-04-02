import Foundation
import Combine
import AppKit

/// Model for managing shelf item selection
class ShelfSelectionModel: ObservableObject {
    @Published var selectedItems: Set<UUID> = []
    @Published var lastSelectedID: UUID?
    
    // MARK: - Selection
    
    var hasSelection: Bool {
        return !selectedItems.isEmpty
    }
    
    var selectionCount: Int {
        return selectedItems.count
    }
    
    func isSelected(_ id: UUID) -> Bool {
        return selectedItems.contains(id)
    }
    
    // MARK: - Single Selection
    
    func select(_ id: UUID) {
        selectedItems.insert(id)
        lastSelectedID = id
    }
    
    func deselect(_ id: UUID) {
        selectedItems.remove(id)
        if lastSelectedID == id {
            lastSelectedID = selectedItems.first
        }
    }
    
    func toggle(_ id: UUID) {
        if selectedItems.contains(id) {
            deselect(id)
        } else {
            select(id)
        }
    }
    
    func selectOnly(_ id: UUID) {
        selectedItems = [id]
        lastSelectedID = id
    }
    
    // MARK: - Batch Selection
    
    func selectAll(_ ids: [UUID]) {
        selectedItems = Set(ids)
        lastSelectedID = ids.last
    }
    
    func deselectAll() {
        selectedItems.removeAll()
        lastSelectedID = nil
    }
    
    func selectRange(from: UUID, to: UUID, in items: [UUID]) {
        guard let fromIndex = items.firstIndex(of: from),
              let toIndex = items.firstIndex(of: to) else {
            return
        }
        
        let range = min(fromIndex, toIndex)...max(fromIndex, toIndex)
        selectedItems = Set(items[range])
        lastSelectedID = to
    }
    
    // MARK: - Advanced Selection
    
    func extendSelection(_ id: UUID, with modifiers: NSEvent.ModifierFlags) {
        if modifiers.contains(.command) {
            toggle(id)
        } else if modifiers.contains(.shift), let _ = lastSelectedID {
            // Range selection - requires items list
        } else {
            selectOnly(id)
        }
    }
    
    func selectNext(in items: [UUID]) {
        guard let lastID = lastSelectedID,
              let index = items.firstIndex(of: lastID),
              index < items.count - 1 else {
            return
        }
        selectOnly(items[index + 1])
    }
    
    func selectPrevious(in items: [UUID]) {
        guard let lastID = lastSelectedID,
              let index = items.firstIndex(of: lastID),
              index > 0 else {
            return
        }
        selectOnly(items[index - 1])
    }
    
    // MARK: - Utilities
    
    func selectedItemsList(from items: [ShelfItem]) -> [ShelfItem] {
        return items.filter { selectedItems.contains($0.id) }
    }
    
    func selectedURLs(from items: [ShelfItem]) -> [URL] {
        return selectedItemsList(from: items).map { $0.url }
    }
}
