//
//  SearchEngine.swift
//  Mac灵动岛
//
//  Fuzzy search and filtering engine for clipboard items
//

import Foundation

final class SearchEngine {
    
    // MARK: - Filter Options
    
    enum ContentFilter: String, CaseIterable, Identifiable {
        case all
        case text
        case images
        case links
        case files
        case pinned
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .all: return "All"
            case .text: return "Text"
            case .images: return "Images"
            case .links: return "Links"
            case .files: return "Files"
            case .pinned: return "Pinned"
            }
        }
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .text: return "doc.plaintext"
            case .images: return "photo"
            case .links: return "link"
            case .files: return "doc"
            case .pinned: return "pin.fill"
            }
        }
        
        func matches(_ item: ClipboardItemV2) -> Bool {
            switch self {
            case .all:
                return true
            case .text:
                return [.text, .richText, .code].contains(item.contentType)
            case .images:
                return item.contentType == .image
            case .links:
                return item.contentType == .url
            case .files:
                return [.file, .pdf].contains(item.contentType)
            case .pinned:
                return item.isPinned
            }
        }
        
        func matches_v1(_ item: IslandClipItem) -> Bool {
            switch self {
            case .all:
                return true
            case .text:
                return item.type == .text || item.type == .code
            case .images:
                return item.type == .image
            case .links:
                return item.type == .url
            case .files:
                return item.content.hasPrefix("file://")
            case .pinned:
                return item.isPinned
            }
        }
    }
    
    // MARK: - Search
    
    /// Perform fuzzy search on items
    func search(query: String, in items: [ClipboardItemV2], filter: ContentFilter = .all) -> [ClipboardItemV2] {
        // Apply filter first
        let filtered = items.filter { filter.matches($0) }
        
        // If query is empty, return filtered list
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return filtered
        }
        
        let queryLower = trimmedQuery.lowercased()
        
        // Rank items by relevance
        let scored: [(item: ClipboardItemV2, score: Int)] = filtered.compactMap { item in
            let score = calculateRelevance(for: item, query: queryLower)
            return score > 0 ? (item, score) : nil
        }
        
        // Sort by score (descending) and return items
        return scored.sorted { $0.score > $1.score }.map { $0.item }
    }
    
    // MARK: - Relevance Scoring
    
    private func calculateRelevance(for item: ClipboardItemV2, query: String) -> Int {
        var score = 0
        let searchableContent = item.searchableContent.lowercased()
        
        // Exact match in content (highest score)
        if searchableContent.contains(query) {
            score += 100
            
            // Bonus for match at start
            if searchableContent.hasPrefix(query) {
                score += 50
            }
        }
        
        // Word-by-word fuzzy matching
        let queryWords = query.split(separator: " ").map(String.init)
        let contentWords = searchableContent.split(separator: " ").map(String.init)
        
        for queryWord in queryWords {
            for contentWord in contentWords {
                if contentWord.contains(queryWord) {
                    score += 10
                } else if levenshteinDistance(queryWord, contentWord) <= 2 {
                    score += 5
                }
            }
        }
        
        // Bonus for matching file name (if file type)
        if [.file, .pdf].contains(item.contentType), 
           let fileName = item.fileDisplayName?.lowercased(),
           fileName.contains(query) {
            score += 30
        }
        
        // Bonus for matching URL domain (if URL type)
        if item.contentType == .url,
           let urlString = item.urlString?.lowercased(),
           urlString.contains(query) {
            score += 30
        }
        
        // Bonus for pinned items
        if item.isPinned {
            score += 5
        }
        
        // Recency bonus (newer items rank slightly higher)
        let ageInHours = Date().timeIntervalSince(item.timestamp) / 3600
        if ageInHours < 24 {
            score += Int(24 - ageInHours) / 4
        }
        
        return score
    }
    
    // MARK: - Levenshtein Distance (fuzzy matching)
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let m = s1.count
        let n = s2.count
        
        if m == 0 { return n }
        if n == 0 { return m }
        
        var matrix = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m {
            matrix[i][0] = i
        }
        
        for j in 0...n {
            matrix[0][j] = j
        }
        
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        
        for i in 1...m {
            for j in 1...n {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // deletion
                    matrix[i][j - 1] + 1,      // insertion
                    matrix[i - 1][j - 1] + cost // substitution
                )
            }
        }
        
        return matrix[m][n]
    }
}
