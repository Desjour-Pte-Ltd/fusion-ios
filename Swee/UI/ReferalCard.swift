import SwiftUI
import SDWebImageSwiftUI

struct ReferalCard: View {
    @State var banner: Banner
    @State private var show = false
    @Environment(\.deeplink) var deeplink

    var background: any View {
        switch banner.background {
        case .image(let url):
            WebImage(url: url) { image in
                image.resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } placeholder: {
                Color.white
                    .skeleton(with: true, shape: .rounded(.radius(12, style: .continuous)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(height: 290)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        case .gradient(let array):
            LinearGradient(colors: array, startPoint: .topLeading, endPoint: .bottomTrailing)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    var body: some View {
        ZStack {
            background.equatable.view
            GeometryReader { metrics in
                VStack(spacing: 8) {
                    HStack {
                        Text(banner.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.custom("Roboto-Bold", size: 24))
                            .foregroundColor(Color.background.white)
                            .shadow(radius: 4, y: 4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    HStack {
                        VStack {
                            Text(banner.description)
                                .frame(maxWidth: metrics.size.width * 0.60, alignment: .leading)
                                .font(.custom("Roboto-Bold", size: 12))
                                .foregroundColor(Color.background.white)
                                .lineLimit(6)
                                .fixedSize(horizontal: false, vertical: true)
                                .sheet(isPresented: $show, content: {
                                    Text("")
                                })
                            Spacer()
                            ZStack {
                                Button {
                                    deeplink.wrappedValue = banner.linkURL?.absoluteString
                                } label: {
                                    HStack {
                                        Image("share")
                                            .foregroundStyle(Color.primary.brand)
                                        Text(banner.buttonTitle)
                                            .font(.custom("Roboto-Bold", size: 14))
                                            .foregroundStyle(Color.primary.brand)
                                    }
                                    .padding([.top, .bottom], 8)
                                    .padding(.leading, 8)
                                    .padding(.trailing, 14)
                                    .background(
                                        Capsule()
                                            .fill(.white.opacity(0.65))
                                            .frame(alignment: .center))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding([.bottom], 24)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack() {
                            Spacer()
                            if let badgeURL = banner.badgeImage {
                                WebImage(url: badgeURL) { image in
                                    image.resizable()
                                        .scaledToFit()
                                } placeholder: {
                                    Color.white
                                        .skeleton(with: true, shape: .circle)
                                        .frame(width: 110, height: 110)
                                }
                                .transition(.fade(duration: 0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .frame(width: 110, height: 110)
                            }
                        }
                        .frame(maxWidth: metrics.size.width * 0.40, alignment: .bottomTrailing)
                        .padding([.bottom], 10)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding([.top], 24)
        }
    }
}
