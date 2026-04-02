import SwiftUI

/// List layout for shelf items
struct ShelfListView: View {
    @ObservedObject var viewModel: ShelfStateViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                ShelfListRowView(item: item)
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct ShelfListRowView: View {
    let item: ShelfItem
    @State private var icon: NSImage?
    
    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let nsImage = icon {
                    Image(nsImage: nsImage)
                        .resizable()
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: item.iconName)
                        .frame(width: 32, height: 32)
                }
            }
            
            VStack(alignment: .leading) {
                Text(item.displayName)
                    .font(.body)
                Text(item.url.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button {
                ShelfStateViewModel.shared.removeItem(item.id)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .task {
            if let resolved = ShelfStateViewModel.shared.resolveFileURL(for: item) {
                self.icon = NSWorkspace.shared.icon(forFile: resolved.path)
            }
        }
    }
}
