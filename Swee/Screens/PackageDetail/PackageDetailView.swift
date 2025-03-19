import SwiftUI
import SDWebImageSwiftUI
import MarkdownUI

struct PackageDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabIsShown) private var tabIsShown
    @EnvironmentObject private var api: API
    @EnvironmentObject private var cart: Cart
    @State private var isExpanded: Bool = false
    @State var package: Package
    
    @State private var hideBottomSheet = true
    @StateObject private var viewModel = PackageDetailViewModel()
    
    var lowerButton: some View {
        VStack(spacing: 0) {
            if viewModel.quantity == 0 {
                AsyncButton(progressWidth: .infinity) {
                    await viewModel.addToCart()
                } label: {
                    HStack {
                        Text("add_to_cart_cta")
                            .font(.custom("Poppins-Medium", size: 18))
                        Image("cart-thick")
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButton())
            } else {
                HStack {
                    Spacer()
                    AsyncButton {
                        await viewModel.decreaseQuantity()
                    } label: {
                        Image("minus")
                    }
                    .tint(.white)
                    Spacer()
                    Text("\(viewModel.quantity)")
                        .font(.custom("Roboto-Bold", size: 24))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        viewModel.increaseQuantity()
                    } label: {
                        Image("plus")
                    }
                    .tint(.white)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: 55)
                .background(Color.primary.brand)
                .clipShape(Capsule())
            }
        }
        .animation(.default, value: viewModel.quantity)
        .padding([.leading, .trailing, .top], 16)
        .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor(Color.text.black10), alignment: .top)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    WebImage(url: package.imageURL) { image in
                        image.resizable()
                            .scaledToFit()
                    } placeholder: {
                        Color.white
                            .skeleton(with: true, shape: .rounded(.radius(12, style: .circular)))
    //                        .frame(width: 70, height: 70)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(package.summary)
                                .font(.custom("Poppins-Bold", size: 20))
                                .foregroundStyle(Color.text.black100)
                            Spacer()
//                            Button {
//                                
//                            } label: {
//                                Image("share-system")
//                                    .tint(Color.text.black80)
//                            }
                        }
                        Text("product_details_by_merchant_title".i18n(with: package.merchant))
                            .font(.custom("Poppins-SemiBold", size: 14))
                            .foregroundStyle(Color.text.black80)
                        if viewModel.stores.count > 0 {
                            HStack(spacing: 4) {
                                Text("product_details_by_merchant_stores_title".i18n(with: viewModel.stores.count.toString))
                                    .font(.custom("Poppins-Regular", size: 12))
                                    .foregroundStyle(Color.text.black60)
                                Image("chevron-right")
                            }
                            .onTapGesture {
                                hideBottomSheet = false
                            }
                        }
                    }
                    .animation(.default, value: viewModel.stores.count)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.black.opacity(0.15))
                    HStack {
                        Text(package.priceString)
                            .font(.custom("Poppins-Bold", size: 20))
                            .foregroundStyle(Color.text.black100)
                        if let originalPrice = package.originalPriceString {
                            Text(originalPrice.strikethroughText(color: Color.text.black60))
                                .font(.custom("Poppins-SemiBold", size: 14))
                                .foregroundStyle(Color.text.black60)
                        }
                    }
                    Markdown(package.description)
                        .markdownTextStyle {
                            FontFamily(.custom("Poppins-Medium"))
                            FontSize(16)
                            ForegroundColor(Color.text.black60)
                        }
                    if viewModel.showError {
                        ContentErrorView {
                            try? await viewModel.fetch()
                        }
                    } else {
                        ForEach(viewModel.package.details.indices, id: \.self) { detail in
                            VStack(alignment: .leading) {
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundStyle(.black.opacity(0.15))
                                Text(viewModel.package.details[detail].title)
                                    .font(.custom("Poppins-Bold", size: 18))
                                    .foregroundStyle(Color.text.black100)
                                    .padding(.vertical, 8)
                                Markdown(viewModel.package.details[detail].content)
                                    .markdownTextStyle {
                                        FontFamily(.custom("Poppins-Medium"))
                                        FontSize(16)
                                        ForegroundColor(Color.text.black60)
                                    }
                            }
                        }
                    }
                    if let tos = package.tos {
                        ZStack {
                            VStack(alignment: .leading) {
                                Text("tnc")
                                    .font(.custom("Poppins-Bold", size: 18))
                                    .foregroundStyle(Color.text.black100)
                                VStack {
                                    Text(tos)
                                        .lineLimit(isExpanded ? nil : 6)
                                        .font(.custom("Poppins-Medium", size: 16))
                                        .foregroundStyle(Color.text.black80)
                                        .overlay(
                                            GeometryReader { proxy in
                                                Button(action: {
                                                    isExpanded.toggle()
                                                }) {
                                                    Text(isExpanded ? "see_less".i18n.underline(font: .custom("Roboto-Medium", size: 16), color: Color.primary.brand) : "see_more".i18n.underline(font: .custom("Roboto-Medium", size: 16), color: Color.primary.brand))
                                                        .padding(.leading, 8.0)
                                                        .background(Color.background.pale)
                                                        .shadow(color: Color.background.pale, radius: 4, x: -8)
                                                }
                                                .frame(width: proxy.size.width, height: proxy.size.height - 2, alignment: .bottomTrailing)
                                            }
                                        )
                                }
                            }
                            .padding()
                            .background(Color.background.pale)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.bottom, 16)
                    }
                }
                .padding([.horizontal, .top], 16)
            }
            lowerButton
                .padding(.bottom, 40)
        }
        .ignoresSafeArea(edges: .bottom)
        .customNavigationTitle(package.title)
        .customNavTrailingItem {
            CartButton()
        }
        .customBottomSheet(hidden: $hideBottomSheet) {
            StoresView(stores: viewModel.stores)
        }
        .onAppear(perform: {
            tabIsShown.wrappedValue = false
            viewModel.package = package
            viewModel.api = api
            viewModel.cart = cart
            Task {
                try? await viewModel.fetch()
            }
        })
    }
}

#Preview {
    PackageDetailView(package: .init(id: .init(uuidString: "4cc469ee-7337-4644-b335-0cb6990a42c2")!, merchant: "Zoomoov", imageURL: nil, title: "Chinese New Year", description: "Some description", summary: "Some summary", price: 1000, originalPrice: 2000, currency: "SGD", details: [], tos: nil))
}
