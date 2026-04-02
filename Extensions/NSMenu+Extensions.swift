import AppKit

extension NSMenu {
    /// Add separator if menu is not empty
    func addSeparatorIfNeeded() {
        if items.count > 0 {
            addItem(NSMenuItem.separator())
        }
    }
    
    /// Add item with action
    @discardableResult
    func addItem(title: String, action: Selector?, keyEquivalent: String = "", target: AnyObject? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = target
        addItem(item)
        return item
    }
    
    /// Remove all items
    func removeAllItems() {
        items.removeAll()
    }
    
    /// Check if menu is empty
    var isEmpty: Bool {
        return items.isEmpty
    }
}
