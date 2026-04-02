import Combine
import Foundation
import AppKit
import UniformTypeIdentifiers

// MARK: - ShelfItem Extensions
// Note: Many properties like isImage, isVideo, isAudio, open() are already
// defined in ShelfItem.swift. This file only adds non-conflicting extensions.

extension ShelfItem {
    /// Icon name based on file type (alternative to iconName)
    var icon: String {
        iconName
    }
    
    /// Formatted file size (alias)
    var sizeFormatted: String {
        fileSizeFormatted
    }
    
    /// Formatted date using createdDate
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdDate)
    }
    
    /// Show file in Finder (with analytics)
    func showInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([url])
        AnalyticsManager.shared.trackAction("show_in_finder", category: "shelf")
    }
    
    /// Get file type (alias for utType)
    var fileType: UTType? {
        utType
    }
    
    /// Check if file is document
    var isDocument: Bool {
        isPDF || isText
    }
}
