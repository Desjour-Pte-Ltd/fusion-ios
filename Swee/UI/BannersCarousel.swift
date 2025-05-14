import SwiftUI
import SDWebImageSwiftUI

struct BannersView: View {
    @Binding var bannerModels: [Banner]
    @Binding var page: Int
    @State private var contentOffset: CGFloat = 0
    
    var body: some View {
        
        ObservableScrollView(.horizontal, showIndicators: false, contentOffset: $contentOffset) {
            LazyHGrid(rows: [.init()]) {
                ForEach(bannerModels.indices, id: \.self) { index in
                    BannerView(banner: bannerModels[index])
                }
            }
            .padding(.horizontal, 16)
            .onChange(of: contentOffset) { newValue in
                var offset = newValue
                offset.negate()
                if offset < 100  {
                    page = 0
                    return
                }
                page = min(Int(offset / 210) + 1, bannerModels.count - 1)
            }
        }
    }
}

extension BannersView: Skeletonable {
    static var skeleton: any View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: [.init()]) {
                ForEach(0...3, id: \.self) { index in
                    BannerView
                        .skeleton.equatable.view
                }
            }
        }
    }
}

struct BannersCarousel: View {
    @State var page: Int = 0
    @State var banners: [Banner]
    
    var body: some View {
        VStack {
            BannersView(bannerModels: $banners, page: $page)
            HStack(spacing: 8, content: {
                ForEach(banners.indices, id:\.self) { index in
                    Capsule()
                        .fill(page == index ? Color(hex: "#17223B") : Color(hex: "#17223B", opacity: 0.20))
                        .frame(width: page == index ? 37 : 8, height: page == index ? 26 : 8, alignment: .center)
                        .animation(.default, value: page)
                        .overlay(
                            Text(page == index ? "\(index + 1)/\(banners.count)" : "")
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundStyle(.white)
                        )
                }
            })
        }
    }
}

struct BannerView: View {
    @State var banner: Banner
    @Environment(\.deeplink) private var deeplink
    
    var body: some View {
        ZStack {
            switch banner.background {
            case .image(let url):
                WebImage(url: url) { image in
                    image.resizable()
                        .scaledToFit()
                } placeholder: {
                    Color.white
                        .skeleton(with: true, shape: .rounded(.radius(12, style: .circular)))
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            case .gradient(let array):
                LinearGradient(colors: array, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            VStack {
                Text(banner.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.custom("Poppins-Bold", size: 14))
                    .foregroundColor(Color.background.white)
                    .shadow(radius: 1, y: 1)
                Text(banner.description)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(Color.background.white)
                Spacer()
                HStack(alignment: .bottom) {
                    if let buttonTitle = banner.buttonTitle {
                        HStack(spacing: 4) {
                            Text(buttonTitle)
                                .font(.custom("Poppins-Medium", size: 10))
                                .foregroundStyle(Color.background.white)
                            Image("circled-arrow-right")
                        }
                        .padding(.bottom, 8)
                    }
                    Spacer()
                    WebImage(url: banner.badgeImage) { image in
                        image.resizable()
                            .scaledToFit()
                    } placeholder: {
                        Color.white
                            .skeleton(with: true, shape: .circle)
                            .frame(width: 70, height: 70)
                    }
                    .transition(.fade(duration: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .frame(width: 70, height: 70)
                }
            }
            .padding(16)
        }
        .onTapGesture {
            guard let deeplink = banner.linkURL?.absoluteString else { return }
            self.deeplink.wrappedValue = deeplink
        }
        .frame(width: 210, height: 190)
    }
}

extension BannerView: Skeletonable {
    static var skeleton: any View {
        Color.white
            .skeleton(with: true, shape: .rounded(.radius(12, style: .circular)))
            .frame(width: 210, height: 190)
    }
}
