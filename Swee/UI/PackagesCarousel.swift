import SwiftUI

struct PackageCarouselModel {
    let sectionID: UUID
    let title: String
    let packages: [Package]
}

struct PackagesCarousel: View {
    @State var model: PackageCarouselModel
    
    private let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        VStack {
            HStack {
                Text(model.title)
                    .textStyle(HomeRowTitleStyle())
                Spacer()
                if model.packages.count > 2 {
                    CustomNavLink(destination: SeeAllView(sectionID: model.sectionID, title: model.title)) {
                        HStack(spacing: 4) {
                            Text("cta_see_all")
                                .font(.custom("Poppins-Regular", size: 14))
                                .foregroundStyle(Color.text.black60)
                            Image("chevron-right")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: [.init()], spacing: 16) {
                    ForEach(model.packages, id: \.id) { package in
                        PackageCard(package: package)
                            .frame(width: 165)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

extension PackagesCarousel: Skeletonable {
    static var skeleton: any View {
        VStack(alignment: .leading, spacing: 14) {
            Text("")
                .skeleton(with: true, shape: .rounded(.radius(12, style: .circular)))
                .frame(maxWidth: 200)
                .frame(height: 20)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: [.init()], spacing: 16) {
                    ForEach(0...2, id: \.self) { index in
                        PackageCard
                            .skeleton
                            .frame(width: 165)
                            .equatable.view
                    }
                }
                .frame(maxHeight: 220)
            }
        }
    }
}
