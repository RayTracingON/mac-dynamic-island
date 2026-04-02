import SwiftUI

/// Toolbar for shelf view with actions and controls
struct ShelfToolbarView: View {
    @ObservedObject var viewModel: ShelfStateViewModel
    @Binding var viewMode: ShelfViewMode
    
    enum ShelfViewMode {
        case grid, list
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                
                TextField("Search files...", text: $viewModel.searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 13))
                
                if !viewModel.searchQuery.isEmpty {
                    Button(action: { viewModel.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
            )
            .frame(maxWidth: 200)
            
            Spacer()
            
            // Item Count
            Text("\(viewModel.items.count) items")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            // View Mode Toggle
            Picker("View Mode", selection: $viewMode) {
                Image(systemName: "square.grid.2x2")
                    .tag(ShelfViewMode.grid)
                Image(systemName: "list.bullet")
                    .tag(ShelfViewMode.list)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 80)
            
            // Sort Menu
            Menu {
                Button("Name") { viewModel.sortOrder = .name }
                Button("Date") { viewModel.sortOrder = .dateAdded }
                Button("Size") { viewModel.sortOrder = .size }
                Button("Type") { viewModel.sortOrder = .type }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14))
                    Text("Sort")
                        .font(.system(size: 12))
                }
            }
            .menuStyle(BorderlessButtonMenuStyle())
            
            // Selection Actions
            if !viewModel.selectedItems.isEmpty {
                Divider()
                    .frame(height: 20)
                
                Text("\(viewModel.selectedItems.count) selected")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Button(action: { viewModel.removeItemsAndClearSelection(Array(viewModel.selectedItems)) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    // Share selected items - functionality to be implemented
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { viewModel.deselectAll() }) {
                    Text("Clear")
                        .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // More Actions
            Menu {
                Button("Clear All") { viewModel.clearAll() }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 16))
            }
            .menuStyle(BorderlessButtonMenuStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Color.gray.opacity(0.05)
        )
    }
}
