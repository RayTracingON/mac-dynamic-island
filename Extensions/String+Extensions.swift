import Foundation

extension String {
    /// Trim whitespace and newlines
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Check if string is empty or whitespace
    var isBlank: Bool {
        return trimmed.isEmpty
    }
    
    /// Convert to URL
    var url: URL? {
        return URL(string: self)
    }
    
    /// Convert to file URL
    var fileURL: URL {
        return URL(fileURLWithPath: self)
    }
    
    // MARK: - Validation
    
    var isValidEmail: Bool {
        let emailRegex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return predicate.evaluate(with: self)
    }
    
    var isValidURL: Bool {
        return url != nil
    }
    
    // MARK: - Manipulation
    
    func truncated(to length: Int, trailing: String = "...") -> String {
        guard count > length else { return self }
        return prefix(length) + trailing
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
    // MARK: - Formatting
    
    var camelCased: String {
        let components = self.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let first = components.first?.lowercased() ?? ""
        let rest = components.dropFirst().map { $0.capitalizingFirstLetter() }
        return ([first] + rest).joined()
    }
    
    var snakeCased: String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(
            in: self,
            range: range,
            withTemplate: "$1_$2"
        ).lowercased() ?? self
    }
    
    // MARK: - Substring
    
    subscript(offset: Int) -> Character {
        return self[index(startIndex, offsetBy: offset)]
    }
    
    subscript(range: Range<Int>) -> Substring {
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(startIndex, offsetBy: range.upperBound)
        return self[start..<end]
    }
    
    // MARK: - Contains
    
    func contains(_ strings: [String]) -> Bool {
        return strings.contains { self.contains($0) }
    }
    
    func containsIgnoringCase(_ string: String) -> Bool {
        return localizedCaseInsensitiveContains(string)
    }
    
    // MARK: - Encoding
    
    var base64Encoded: String? {
        return data(using: .utf8)?.base64EncodedString()
    }
    
    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - File System
    
    var lastPathComponent: String {
        return (self as NSString).lastPathComponent
    }
    
    var pathExtension: String {
        return (self as NSString).pathExtension
    }
    
    var deletingLastPathComponent: String {
        return (self as NSString).deletingLastPathComponent
    }
    
    var deletingPathExtension: String {
        return (self as NSString).deletingPathExtension
    }
    
    func appendingPathComponent(_ component: String) -> String {
        return (self as NSString).appendingPathComponent(component)
    }
    
    func appendingPathExtension(_ ext: String) -> String? {
        return (self as NSString).appendingPathExtension(ext)
    }
}
