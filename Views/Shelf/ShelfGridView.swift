import SwiftUI

struct ShelfGridView: View {
    @ObservedObject var viewModel: ShelfStateViewModel
    
    let columns = [
        GridItem(.adaptive(minimum: 96), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.items) { item in
                    ShelfItemView(
                        viewModel: ShelfItemViewModel(item: item),
                        onDelete: {
                            viewModel.removeItem(item.id)
                        }
                    )
                }
            }
            .padding()
        }
    }
}
