import SwiftUI
import SDWebImageSwiftUI
import StripePaymentSheet
import StripePaymentsUI

extension CartItem {
    func priceString(currencyCode: String) -> String {
        return "\(currencyCode) \(String(format: "%.2f", Double(totalPriceCents / 100)))"
    }
    
    func pricePerItemString(currencyCode: String) -> String {
        return "\(currencyCode) \(String(format: "%.2f", Double(pricePerItem / 100)))"
    }
}

struct BlinkViewModifier: ViewModifier {
    
    let duration: Double
    @State private var blinking: Bool = false
    
    func body(content: Content) -> some View {
        content
            .opacity(blinking ? 0 : 1)
            .animation(.easeOut(duration: duration).repeatForever(), value: blinking)
            .onAppear {
                withAnimation {
                    blinking = true
                }
            }
    }
}

extension View {
    func blinking(duration: Double = 0.75) -> some View {
        modifier(BlinkViewModifier(duration: duration))
    }
}

struct CheckoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabIsShown) private var tabIsShown
    @Environment(\.currentTab) private var selectedTab
    @Environment(\.navView) private var navView
    @EnvironmentObject private var cart: Cart
    @StateObject private var viewModel = CheckoutViewModel()
    
    //    @State private var text: String = ""
    @State private var showPaymentSheet = false
    //    @State private var showPaymentSuccess: Bool = false
    
    var mainUI: some View {
        VStack(spacing: 0) {
            ScrollView {
                HStack {
                    Text("checkout_items_counts".i18n(with: viewModel.quantity.toString))
                        .font(.custom("Poppins-Bold", size: 20))
                    Spacer()
                }
                .padding([.horizontal, .top], 16)
                LazyVGrid(columns: [.init(.flexible())], spacing: 0) {
                    ForEach(cart.packages, id: \.id) { element in
                        HStack {
                            WebImage(url: element.packageDetails?.photoURL) { image in
                                image.resizable()
                            } placeholder: {
                                Color.white
                                    .skeleton(with: true, shape: .rounded(.radius(4, style: .circular)))
                                //                                    .frame(width: 127, height: 145)
                            }
                            .frame(width: 127, height: 127)
                            .transition(.fade(duration: 0.5))
                            .scaledToFill()
                            .frame(minWidth: 0)
                            .edgesIgnoringSafeArea(.all)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .padding(.trailing, 16)
                            VStack(alignment: .leading) {
                                Text(element.packageDetails?.name)
                                    .foregroundStyle(Color.text.black100)
                                    .font(.custom("Poppins-SemiBold", size: 16))
                                Text(element.packageDetails?.productSummary)
                                    .foregroundStyle(Color.text.black80)
                                    .font(.custom("Poppins-Medium", size: 12))
                                Text("checkout_item_unit_price".i18n(with: element.pricePerItemString(currencyCode: cart.currencyCode)))
                                    .foregroundStyle(Color.text.black80)
                                    .font(.custom("Poppins-Medium", size: 12))
                                Spacer()
                                HStack {
                                    if cart.inProgress && cart.refreshingPackageID == element.packageId {
                                        Text(element.priceString(currencyCode: cart.currencyCode))
                                            .foregroundStyle(Color.text.black100)
                                            .font(.custom("Poppins-SemiBold", size: 14))
                                            .blinking()
                                        //                                            .skeleton(with: cart.inProgress, size: CGSize(width: CGFloat.infinity, height: 20), shape: .rounded(.radius(4, style: .circular)))
                                    } else {
                                        Text(element.priceString(currencyCode: cart.currencyCode))
                                            .foregroundStyle(Color.text.black100)
                                            .font(.custom("Poppins-SemiBold", size: 14))
                                    }
                                    Spacer()
                                    HStack {
                                        AsyncButton {
                                            await viewModel.decreaseQuantity(for: element)
                                        } label: {
                                            Image("minus")
                                                .resizable()
                                                .frame(width: 16, height: 16)
                                        }
                                        .tint(Color.secondary.brand)
                                        Spacer()
                                        Text("\(element.quantity)")
                                            .font(.custom("Poppins-Bold", size: 16))
                                            .foregroundStyle(Color.secondary.brand)
                                            .lineLimit(1)
                                        Spacer()
                                        Button {
                                            viewModel.increaseQuantity(for: element)
                                        } label: {
                                            Image("plus")
                                                .resizable()
                                                .frame(width: 16, height: 16)
                                        }
                                        .tint(Color.secondary.brand)
                                    }
                                    .frame(maxWidth: 90)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .clipShape(Capsule())
                                    .overlay(RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.secondary.brand,
                                                lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(16)
                    }
                }
                .background(Color.background.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                VStack(alignment: .leading) {
                    Text("checkout_order_summary_title".i18n)
                        .font(.custom("Poppins-Bold", size: 16))
                        .padding(.bottom, 16)
                    //                    HStack {
                    //                        TextField("Enter coupon code", text: $text)
                    //                            .padding(.horizontal, 16)
                    //                            .padding(.vertical, 12)
                    //                            .overlay(RoundedRectangle(cornerRadius: 4)
                    //                                .stroke(.black.opacity(0.15),
                    //                                        lineWidth: 1)
                    //                            )
                    //                        Button {
                    //
                    //                        } label: {
                    //                            Text("Apply")
                    //                                .font(.custom("Roboto-Bold", size: 16))
                    //                                .foregroundStyle(Color.text.black80)
                    //                        }
                    //                        .padding(.vertical, 12)
                    //                        .padding(.horizontal, 32)
                    //                        .clipShape(Capsule())
                    //                        .overlay(RoundedRectangle(cornerRadius: 24)
                    //                            .stroke(Color.text.black20,
                    //                                    lineWidth: 1)
                    //                        )
                    //                    }
                    //                    .padding(.bottom, 24)
                    SummaryRow(title: "checkout_order_summary_price_before_fees", price: viewModel.cartTotal, currency: cart.currencyCode, blinking: cart.inProgress)
                        .padding(.bottom, 4)
                    if let fees = cart.fees {
                        ForEach(fees.indices, id: \.self) { index in
                            let fee = fees[index]
                            SummaryRow(title: "\(fee.name) \(fee.rateMilli / 1000)%",
                                       price: Double(fee.amountCents / 100),
                                       currency: cart.currencyCode,
                                       blinking: cart.inProgress)
                            .padding(.bottom, 19)
                        }
                    }
                    Rectangle()
                        .fill(.black.opacity(0.05))
                        .frame(height: 1)
                        .padding(.bottom, 8)
                    SummaryRow(title: "checkout_order_summary_total_price",
                               price: viewModel.finalTotal,
                               allBold: true,
                               currency: cart.currencyCode,
                               blinking: cart.inProgress)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color.background.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding([.horizontal, .bottom], 16)
            }
            
            BottomButtonContainer {
                if let paymentSheet = viewModel.paymentSheet {
                    AsyncButton(progressWidth: .infinity) {
                        try? await viewModel.prepareForPayment()
                        showPaymentSheet = true
                    } label: {
                        HStack {
                            Text("checkout_proceed_cta".i18n)
                                .font(.custom("Roboto-Bold", size: 16))
                        }
                        .foregroundStyle(Color.background.white)
                        .frame(maxWidth: .infinity)
                    }
                    .paymentSheet(
                        isPresented: $showPaymentSheet,
                        paymentSheet: paymentSheet,
                        onCompletion: viewModel.onPaymentCompletion)
                    .disabled(cart.inProgress)
                    .buttonStyle(PrimaryButton())
                } else {
                    Button {} label: {
                        HStack {
                            Text("checkout_proceed_cta".i18n)
                                .font(.custom("Roboto-Bold", size: 16))
                        }
                        .foregroundStyle(Color.background.white)
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(true)
                    .buttonStyle(PrimaryButton())
                }
            }
            .padding(.bottom, 40)
            
        }
        .animation(.default, value: cart.updatedAt)
        .ignoresSafeArea(edges: .bottom)
        .background(Color.background.pale)
    }
    
    var successUI: some View {
        StateView(image: .success,
                  title: "checkout_success_title",
                  description: "checkout_success_message",
                  buttonTitle: "checkout_success_cta") {
            cart.reset()
            dismiss()
            selectedTab.wrappedValue = .myWallet
        }
    }
    
    var emptyUI: some View {
        StateView(image: .success,
                  title: "checkout_empty_title",
                  description: "checkout_empty_message",
                  buttonTitle: "checkout_empty_cta") {
            if selectedTab.wrappedValue == .home {
                navView.wrappedValue?.popToRootViewController(animated: true)
            } else {
                dismiss()
                selectedTab.wrappedValue = .home
            }
        }
    }
    
    var errorUI: some View {
        StateView.error {
            try? await viewModel.fetch()
        }
    }
    
    var failedPaymentUI: some View {
        StateView(image: .custom("cart-error"),
                  title: "checkout_failed_title",
                  description: "checkout_failed_message",
                  buttonTitle: "checkout_failed_cta") {
            try? await viewModel.prepareForPayment()
        }
    }
    
    var body: some View {
        VStack {
            switch viewModel.state {
            case .loaded:
                mainUI
            case .empty:
                emptyUI
            case .error:
                errorUI
            case .paymentSucceeded:
                successUI
            case .paymentFailed:
                failedPaymentUI
            }
        }
        .customNavigationTitle("checkout_title")
        .customNavigationBackButtonHidden(true)
        .customNavLeadingItem {
            Button {
                if viewModel.state == .paymentSucceeded {
                    cart.reset()
                }
                dismiss()
            } label: {
                Image("back")
            }
        }
        .onAppear(perform: {
            viewModel.cart = cart
            //            viewModel.preparePaymentSheet()
            Task {
                try? await viewModel.fetch()
                try? await viewModel.prepareForPayment()
            }
            tabIsShown.wrappedValue = false
        })
    }
}

struct BottomButtonContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding([.leading, .trailing, .top], 16)
        .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor(Color.text.black10), alignment: .top)
    }
}

struct SummaryRow: View {
    var title: String
    var price: Double
    var allBold: Bool = false
    var currency: String
    var blinking: Bool = false
    
    var body: some View {
        HStack {
            Text(title.i18n)
                .font(allBold ? .custom("Poppins-SemiBold", size: 18) : .custom("Poppins-Medium", size: 16))
                .foregroundStyle(allBold ? Color.text.black100 : Color.text.black60)
            Spacer()
            if blinking {
                HStack {
                    Text("\(currency) ")
                        .font(.custom("Poppins-SemiBold", size: 16))
                    + Text("\(price, specifier: "%.2f")")
                        .font(.custom(allBold ? "Poppins-Bold" : "Poppins-Regular", size: 16))
                }
                .blinking()
            } else {
                HStack {
                    Text("\(currency) ")
                        .font(.custom("Poppins-SemiBold", size: 16))
                    + Text("\(price, specifier: "%.2f")")
                        .font(.custom(allBold ? "Poppins-Bold" : "Poppins-Regular", size: 16))
                }
            }
        }
    }
}

#Preview {
    CustomNavView {
        CheckoutView()
    }
}
