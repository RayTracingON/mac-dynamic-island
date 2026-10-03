import Foundation

/// Convenient shorthand: L("key") for localized strings
func L(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}
