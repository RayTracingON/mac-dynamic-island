import SwiftUI

/// IslandChrome — reusable Dynamic Island container that wraps existing DynamicIslandChrome
/// This satisfies naming in requirements while reusing the proven visual implementation.
public struct IslandChrome<Content: View>: View {
    private let isExpanded: Bool
    private let content: Content

    public init(isExpanded: Bool, @ViewBuilder content: () -> Content) {
        self.isExpanded = isExpanded
        self.content = content()
    }

    public var body: some View {
        DynamicIslandChrome(isExpanded: isExpanded) {
            content
        }
    }
}

public extension View {
    func islandChrome(isExpanded: Bool) -> some View {
        IslandChrome(isExpanded: isExpanded) {
            self
        }
    }
}
