//
//  IslandLayoutConstants.swift
//  Mac灵动岛
//
//  LAYOUT GUARD: Immutable layout rules that protect system feel
//  
//  WHY THIS EXISTS:
//  - Prevents "just one more item" feature creep
//  - Ensures island never sprawls wider (maintains macOS-native feel)
//  - Guarantees 6-item visibility contract in Peek state
//  - Centralizes all layout decisions (no scattered magic numbers)
//
//  RULES:
//  1. These constants are SYSTEM INVARIANTS, not preferences
//  2. Changes here require explicit design review
//  3. Width cannot expand to "fit content" - content must adapt to width
//

import Foundation
import CoreGraphics

/// Layout constants that enforce Dynamic Island geometry discipline
/// 
/// CRITICAL: These are NOT tunable parameters. They define the system contract.
/// Violating these rules breaks macOS-native feel and spatial memory.
enum IslandLayoutConstants {
    
    // MARK: - Width Discipline (NON-NEGOTIABLE)
    
    /// Compact pill width (system-constrained, never grows)
    /// Reference: macOS Menu Bar widgets, Spotlight pill
    static let compactWidth: CGFloat = 280
    
    /// Expanded panel width (locked to system overlay range)
    /// Reference: Raycast (~600pt), Control Center sections (560-600pt)
    /// 
    /// WHY 640pt:
    /// - Wide enough for 3-column grid + action buttons + full text labels
    /// - Matches macOS native overlay width range (Spotlight ~680pt)
    /// - Ensures all UI elements are fully visible without truncation
    static let expandedWidth: CGFloat = 640
    
    /// GUARD: Width cannot vary
    /// If content needs more space, it scrolls or wraps - width NEVER grows
    static let minExpandedWidth: CGFloat = expandedWidth
    static let maxExpandedWidth: CGFloat = expandedWidth
    
    // MARK: - Height Discipline
    
    /// Compact pill height (tight, breathable)
    static let compactHeight: CGFloat = 36
    
    /// Expanded panel height (fits 2-row grid + command strip + pinned section comfortably)
    /// Increased from 360 to ensure 6 clipboard items are fully visible
    static let expandedHeight: CGFloat = 420
    
    // MARK: - Peek State Contract (6-ITEM GUARANTEE)
    
    /// Number of items ALWAYS visible in Peek state without scrolling
    /// 
    /// WHY EXACTLY 6:
    /// - Fits 2×3 grid perfectly in 580pt width
    /// - Provides sufficient context without overwhelming
    /// - Matches macOS system overlay density (Control Center, Raycast)
    /// 
    /// RULE: This NEVER changes based on content, screen size, or user preference
    static let peekVisibleItemCount: Int = 6
    
    // MARK: - Grid Contract (2×3 LAYOUT)
    
    /// Column count in Peek grid (FIXED, never adaptive)
    /// RULE: Do NOT use adaptive columns or "fit to width" logic
    static let peekGridColumns: Int = 3
    
    /// Row count visible in Peek without scrolling
    static let peekGridRows: Int = 2
    
    /// Grid item spacing (horizontal and vertical)
    /// Reduced from 12pt for denser, more system-like packing
    static let gridSpacing: CGFloat = 10
    
    // MARK: - Card Dimensions
    
    /// Individual card height in grid
    /// Set to 110pt to ensure content (preview + metadata + action buttons) fits comfortably
    static let gridCardHeight: CGFloat = 110
    
    /// Card corner radius (subtle, not prominent)
    static let gridCardCornerRadius: CGFloat = 10
    
    /// Card internal padding
    static let gridCardPadding: CGFloat = 12
    
    // MARK: - Grid Height (FIXED, NOT SCROLLABLE)
    
    /// FIXED height for 2-row grid (NO SCROLLING)
    /// Calculation: (cardHeight × 2) + (spacing × 1)
    /// = (110 × 2) + 10 = 230pt
    /// This ensures exactly 6 items (2×3) are visible without scrolling
    static let peekGridMaxHeight: CGFloat = 230
    
    // MARK: - Validation (DEBUG ONLY)
    
    #if DEBUG
    /// Assert layout invariants are maintained
    static func validatePeekLayout(visibleItemCount: Int, columns: Int) {
        assert(visibleItemCount == peekVisibleItemCount,
               "⚠️ LAYOUT GUARD VIOLATION: Peek state must show exactly \(peekVisibleItemCount) items, got \(visibleItemCount)")
        
        assert(columns == peekGridColumns,
               "⚠️ LAYOUT GUARD VIOLATION: Peek grid must have exactly \(peekGridColumns) columns, got \(columns)")
    }
    
    /// Assert width discipline is maintained
    static func validateWidth(actual: CGFloat, expected: CGFloat, context: String) {
        let tolerance: CGFloat = 1.0  // Allow 1pt rounding tolerance
        assert(abs(actual - expected) <= tolerance,
               "⚠️ WIDTH GUARD VIOLATION (\(context)): Expected \(expected)pt, got \(actual)pt")
    }
    #endif
}

// MARK: - Usage Guidelines

/*
 HOW TO USE THIS FILE:
 
 ✅ CORRECT:
 - Use these constants directly in layout code
 - Reference them in documentation/comments
 - Update them only after explicit design review
 
 ❌ INCORRECT:
 - Creating local "adjusted" versions
 - Computing layout based on content size
 - Adding "just one more item" without updating contract
 - Making width adaptive or content-driven
 
 EXAMPLES:
 
 // ✅ Width discipline
 .frame(width: IslandLayoutConstants.expandedWidth)
 
 // ✅ Item count contract
 ForEach(items.prefix(IslandLayoutConstants.peekVisibleItemCount))
 
 // ✅ Grid contract
 LazyVGrid(columns: Array(repeating: GridItem(.flexible()), 
                          count: IslandLayoutConstants.peekGridColumns))
 
 // ❌ NEVER do this
 .frame(maxWidth: .infinity)  // Violates width discipline
 ForEach(items)  // Violates item count contract
 LazyVGrid(columns: adaptiveColumns())  // Violates grid contract
 */
