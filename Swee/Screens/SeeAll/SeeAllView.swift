import SwiftUI

struct SeeAllView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabIsShown) private var tabIsShown
    
    @StateObject private var viewModel = SeeAllViewModel()
    @State var sectionID: UUID
    @State var title: String
    
    var columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.showError {
                StateView.error {
                    try? await viewModel.fetch(with: sectionID)
                }
            } else {
                ScrollView {
                    if viewModel.loadedData {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.packages.indices, id: \.self) { index in
                                PackageCard(package: viewModel.packages[index])
                            }
                        }
                        .padding([.leading, .trailing, .top], 16)
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(0...4, id: \.self) { index in
                                PackageCard.skeleton.equatable.view
                            }
                        }
                        .padding([.leading, .trailing, .top], 16)
                    }
                }
            }
        }
        .customNavigationTitle(title)
        .customNavTrailingItem {
            CartButton()
        }
        .onAppear(perform: {
            Task {
                try? await viewModel.fetch(with: sectionID)
            }
            tabIsShown.wrappedValue = false
            Analytics.capture(.seeAllProductsScreen(title))
        })
    }
}

#Preview {
    SeeAllView(sectionID: .init(uuidString: "5B752D23-23CD-4EBC-B7D4-4B62E570D0A8")!, title: "Packages just for you")
}
