import SwiftUI
import SDWebImageSwiftUI
import SwiftUIIntrospect

struct MerchantPageView: View {
    @State private var size: CGRect = .zero
    @State private var topInset: Double = 0
    @State private var hideBottomSheet = true
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabIsShown) private var tabIsShown
    @EnvironmentObject private var api: API
    @EnvironmentObject private var locationManager: LocationManager
    
    @State var merchant: Merchant
    @StateObject var viewModel = MerchantPageViewModel()
    @State private var isExpanded: Bool = false
    
    var columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    private var positionDetector: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .global)
            Color.clear
                .onChange(of: frame) { newVal in
                    size = newVal
                }
        }
    }
    
    private var bgImage: some View {
        GeometryReader { proxy in
            let h = proxy.size.height
            let minY = proxy.frame(in: .global).minY
            WebImage(url: merchant.storeImageURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.white
                    .skeleton(with: true, shape: .rectangle)
            }
            .transition(.fade(duration: 0.5))
            .scaledToFill()
            .frame(height: max(h, size.maxY - 60))
            .frame(maxWidth: proxy.size.width)
            .offset(y: min(0, -minY + topInset + 80))
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let insets = geometry.safeAreaInsets
            ScrollView {
                VStack {
                    VStack(spacing: 0) {
                        VStack {
                            Spacer()
                            HStack {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(merchant.name)
                                        .font(.custom("Poppins-Bold", size: 24))
                                        .foregroundStyle(.white)
                                    if !viewModel.stores.isEmpty {
                                        Text("merchant_store_locations_title".i18n(with: viewModel.stores.count.toString)
                                            .underline(font: .custom("Poppins-SemiBold", size: 14),
                                                       color: .white))
                                        .onTapGesture {
                                            hideBottomSheet = false
                                        }
                                    }
                                }
                                Spacer()
                                //                                Image("share-system")
                                //                                    .foregroundStyle(.white)
                            }
                            .padding([.leading, .trailing], 16)
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 40)
                        .background(LinearGradient(colors: [.black, .black.opacity(0.2), .clear], startPoint: .bottom, endPoint: .top))
                    }
                    .padding(.bottom, -40)
                    .onChange(of: size) { newVal in
                        topInset = insets.top
                    }
                    .background { positionDetector }
                    .background { bgImage }
                    VStack(alignment: .leading, spacing: 20) {
                        if let description = merchant.description {
                            //                            Text(description)
                            //                                .font(.custom("Poppins-Medium", size: 16))
                            //                                .foregroundStyle(Color.text.black80)
                            Text(description)
                                .lineLimit(isExpanded ? nil : 6)
                                .font(.custom("Poppins-Medium", size: 16))
                                .foregroundStyle(Color.text.black80)
                                .padding(.bottom, isExpanded ? 20 : 0)
                                .overlay(
                                    GeometryReader { proxy in
                                        Button(action: {
                                            isExpanded.toggle()
                                        }) {
                                            Text(isExpanded ? "see_less".i18n.underline(font: .custom("Roboto-Medium", size: 16), color: Color.primary.brand) : "see_more".i18n.underline(font: .custom("Roboto-Medium", size: 16), color: Color.primary.brand))
                                                .padding(.leading, 8.0)
                                                .shadow(color: Color.background.pale, radius: 4, x: -8)
                                        }
                                        .frame(width: proxy.size.width, height: proxy.size.height - 2, alignment: .bottomTrailing)
                                    }
                                )
                                .zIndex(3)
                        }
                        // NOTE: this was moved for an upcoming release
                        //                        VStack(alignment: .leading) {
                        //                            Text("Legendary deals just for today")
                        //                                .font(.custom("Poppins-Bold", size: 20))
                        //                            DealBanner(banner: .init(expiryDate: "06:00 hrs left",
                        //                                                     title: "Super hero Tuesday",
                        //                                                     description: "One free ride when you bring Zoomoov hero mask",
                        //                                                     image: .init("badge-2"),
                        //                                                     bgColors: [Color(hex:"#3900B1"), Color(hex:"#9936CE"), Color(hex:"#FDC093")],
                        //                                                     timerColors: [Color(hex: "#FFC107"), Color(hex: "#FFC107", opacity: 0)]))
                        //                        }
                        Text("merchant_packages_title")
                            .font(.custom("Poppins-Bold", size: 20))
                        if viewModel.showError {
                            ContentErrorView {
                                try? await viewModel.fetch(with: merchant.id.uuidString)
                            }
                        } else if viewModel.packages.isEmpty {
                            HStack(spacing: 16) {
                                PackageCard.skeleton.equatable.view
                                PackageCard.skeleton.equatable.view
                            }
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(viewModel.packages, id: \.id) { package in
                                    PackageCard(package: package)
                                        .id(package.id)
                                }
                            }
                        }
                        Text("merchant_nearby_locations_title")
                            .font(.custom("Poppins-Bold", size: 20))
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHGrid(rows: [.init()], content: {
                                if viewModel.stores.isEmpty {
                                    ForEach(0..<2, id: \.self) { _ in
                                        VenueCard.skeleton.equatable.view
                                    }
                                } else {
                                    ForEach(viewModel.stores.indices, id: \.self) { index in
                                        VenueCard(model: viewModel.stores[index])
                                    }
                                }
                            })
                        }
                        .padding(.bottom, 20)
                        .introspect(.scrollView, on: .iOS(.v15, .v16, .v17, .v18), customize: { scrollView in
                            scrollView.clipsToBounds = false
                        })
                    }
                    .padding([.leading, .trailing, .top], 16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(.bottom, 30)
                .animation(.snappy, value: isExpanded)
            }
            .ignoresSafeArea()
            .customNavigationTitle(merchant.name)
            .customNavTrailingItem {
                CartButton()
            }
            .customBottomSheet(hidden: $hideBottomSheet) {
                StoresView(stores: viewModel.stores)
            }
        }
        .onAppear(perform: {
            print("Run on Appear!!! \(Date())")
            viewModel.locationManager = locationManager
            viewModel.api = api
            viewModel.merchant = merchant
            Task {
                try? await viewModel.fetch(with: merchant.id.uuidString)
            }
            tabIsShown.wrappedValue = false
        })
        .onFirstAppear {
            isExpanded = !viewModel.longDescription
        }
    }
}

struct DealBannerModel {
    let expiryDate: String
    let title: String
    let description: String
    let image: Image
    let bgColors: [Color]
    let timerColors: [Color]
}

struct DealBanner: View {
    @State var banner: DealBannerModel
    
    var body: some View {
        ZStack{
            HStack {
                VStack {
                    Text(banner.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.custom("Poppins-Bold", size: 18))
                        .foregroundColor(Color.background.white)
                        .shadow(radius: 1, y: 1)
                        .padding(.top, 15)
                    Text(banner.description)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.custom("Poppins-SemiBold", size: 12))
                        .foregroundColor(Color.background.white.opacity(0.75))
                    HStack(alignment: .bottom) {
                        HStack(spacing: 4) {
                            Text("add_to_cart_cta")
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundStyle(Color.background.white)
                            Image("cart")
                                .resizable()
                                .foregroundColor(.white)
                                .frame(width: 18, height: 18)
                        }
                        .padding([.leading, .trailing], 12)
                        .padding([.top, .bottom], 4)
                        .background(
                            Capsule()
                                .foregroundStyle(.white.opacity(0.2)))
                        Spacer()
                    }
                    .padding(.top, 20)
                }
                Spacer()
                VStack {
                    Spacer()
                    banner.image
                        .frame(width: 90, height: 90)
                }
            }
            .padding()
            .background(LinearGradient(colors: banner.bgColors, startPoint: .topLeading, endPoint: .bottomTrailing))
            VStack {
                HStack {
                    HStack {
                        Text(banner.expiryDate)
                            .font(.custom("Poppins-Bold", size: 12))
                            .foregroundStyle(.white)
                            .shadow(radius: 0, y: 1)
                    }
                    .padding([.trailing], 40)
                    .padding([.leading], 10)
                    .padding([.top], 4)
                    .background(LinearGradient(colors: banner.timerColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    Spacer()
                }
                Spacer()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct VenueCard: View {
    @State var model: MerchantStore
    
    var body: some View {
        ZStack {
            WebImage(url: model.imageURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.white
                    .skeleton(with: true, shape: .rectangle)
            }
            .transition(.fade(duration: 0.5))
            .frame(minWidth: 0, maxHeight: 230)
            .edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading) {
                Spacer()
                HStack {
                    VStack(alignment: .leading) {
                        Text(model.name)
                            .font(.custom("Roboto-Bold", size: 14))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.25), radius: 0, y: 2)
                        Text(model.distance)
                            .font(.custom("Roboto-Bold", size: 12))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .padding(16)
                .background(LinearGradient(colors: [.black.opacity(0.9), Color(hex: "#D9D9D9", opacity: 0)], startPoint: .bottom, endPoint: .top))
            }
        }
        .frame(width: 200, height: 230)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension VenueCard: Skeletonable {
    static var skeleton: any View {
        Color.white
            .skeleton(with: true, shape: .rounded(.radius(12, style: .circular)))
            .frame(maxWidth: .infinity)
            .frame(width: 200, height: 230)
    }
}

#Preview {
    CustomNavView {
        MerchantPageView(merchant: .init(id: .init(uuidString: "5b752d23-23cd-4ebc-b7d4-4b62e570d0a8")!, name: "Zoomoov", description: "Some description", backgroundImage: nil, backgroundColors: [], storeImageURL: nil))
    }
}
