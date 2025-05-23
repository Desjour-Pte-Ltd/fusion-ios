import SwiftUI
import SDWebImageSwiftUI

struct PackageCard: View {
    @State var package: Package
    @State private var imageLoaded = false
    @Environment(\.country) var country
        
    var body: some View {
        CustomNavLink(destination: PackageDetailView(package: package)) {
            VStack {
                ZStack {
                    WebImage(url: package.imageURL) { image in
                        image.resizable()
                    } placeholder: {
                        Color.white
                            .skeleton(with: true, shape: .rounded(.radius(4, style: .circular)))
                            .frame(width: 165, height: 165)
                    }
                    .transition(.fade(duration: 0.5))
                    .scaledToFill()
                    .frame(minWidth: 0)
                    .edgesIgnoringSafeArea(.all)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .frame(maxWidth: 165, maxHeight: 165)
                Text(package.title)
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundStyle(Color.text.black100)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                Text(package.merchant)
                    .font(.custom("Poppins-Medium", size: 12))
                    .foregroundStyle(Color.text.black60)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                Text(package.summary)
                    .font(.custom("Poppins-Medium", size: 12))
                    .foregroundStyle(Color.text.black60)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                HStack {
                    if let originalPrice = package.originalPriceString(in: country.wrappedValue) {
                        Text(originalPrice.strikethroughText())
                            .font(.custom("Poppins-Medium", size: 10))
                            .foregroundStyle(Color.text.black40)
                    }
                    Text(package.priceString(in: country.wrappedValue))
                        .font(.custom("Poppins-SemiBold", size: 12))
                    Spacer()
                }
            }
        }
        .buttonStyle(EmptyStyle())
    }
}

extension PackageCard: Skeletonable {
    static var skeleton: any View {
        VStack(alignment: .leading) {
            Color.white
                .skeleton(with: true, shape: .rounded(.radius(12, style: .circular)))
                .frame(maxWidth: 165)
                .frame(height: 165)
            Text("")
                .skeleton(with: true, shape: .rounded(.radius(12, style: .circular)))
                .frame(maxWidth: 165)
                .frame(height: 15)
            Text("")
                .skeleton(with: true, shape: .rounded(.radius(12, style: .circular)))
                .frame(maxWidth: 165)
                .frame(height: 10)
            Text("")
                .skeleton(with: true, shape: .rounded(.radius(12, style: .circular)))
                .frame(maxWidth: 80)
                .frame(height: 10)
        }
    }
}

#Preview {
    PackageCard.skeleton.equatable.view
        .frame(maxWidth: 160)
}
