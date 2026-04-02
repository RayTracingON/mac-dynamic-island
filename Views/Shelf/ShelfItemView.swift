import SwiftUI
import QuickLook

/// Individual shelf item card view
struct ShelfItemView: View {
    @ObservedObject var viewModel: ShelfItemViewModel
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Thumbnail logic extracted for compiler performance
            thumbnailView
            
            // File Name
            Text(viewModel.fileName)
                .font(.system(size: 11))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    viewModel.isSelected ? Color.accentColor : (isHovering ? Color.white.opacity(0.3) : Color.clear),
                    lineWidth: 2
                )
        )
        .onTapGesture {
            viewModel.isSelected.toggle()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
                viewModel.isHovered = hovering
            }
        }
        .contextMenu {
            Button("Quick Look") { viewModel.quickLook() }
            Button("Open") { viewModel.open() }
            Divider()
            Button("Share...") { viewModel.share() }
            Button("Show in Finder") { viewModel.revealInFinder() }
            Divider()
            Button("Copy URL") { viewModel.copyURL() }
            Button("Copy Path") { viewModel.copyPath() }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
        .onAppear {
            viewModel.loadThumbnail()
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        ZStack {
            if let thumbnail = viewModel.thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if viewModel.isLoading {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(ProgressView().scaleEffect(0.5))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: viewModel.item.iconName)
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                    )
            }
            
            // Quick Look Button (on hover)
            if isHovering {
                Button(action: { viewModel.quickLook() }) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale)
            }
        }
    }
}
