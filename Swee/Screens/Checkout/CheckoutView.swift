import SwiftUI
import SDWebImageSwiftUI
import StripePaymentSheet
import StripePaymentsUI

extension CartItem {
    func priceString(currencyCode: String, in country: Country) -> String {
        return Double(totalPriceCents / 100).toPrice(currencyCode: currencyCode, localeIdentifier: country.localeIdentifier)
    }
    
    func pricePerItemString(currencyCode: String, in country: Country) -> String {
        return Double(pricePerItem / 100).toPrice(currencyCode: currencyCode, localeIdentifier: country.localeIdentifier)
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
    func blinking(when shouldBlink: Bool = true, duration: Double = 0.75) -> some View {
        if shouldBlink {
            return AnyView(self.modifier(BlinkViewModifier(duration: duration)))
        } else {
            return AnyView(self)
        }
    }
}

struct CheckoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabIsShown) private var tabIsShown
    @Environment(\.currentTab) private var selectedTab
    @Environment(\.navView) private var navView
    @Environment(\.country) private var country
    @Environment(\.route) private var route
    @EnvironmentObject private var cart: Cart
    @StateObject private var viewModel = CheckoutViewModel()
    @State private var showSafari = false
    @State private var paymentLink: PaymentLink?
    @State private var showPaymentSheet = false
    @State private var coupon: String = ""
    
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
                                Text("checkout_item_unit_price".i18n(with: element.pricePerItemString(currencyCode: cart.currencyCode, in: country.wrappedValue)))
                                    .foregroundStyle(Color.text.black80)
                                    .font(.custom("Poppins-Medium", size: 12))
                                Spacer()
                                HStack {
                                    if cart.inProgress && cart.refreshingPackageID == element.packageId {
                                        Text(element.priceString(currencyCode: cart.currencyCode, in: country.wrappedValue))
                                            .foregroundStyle(Color.text.black100)
                                            .font(.custom("Poppins-SemiBold", size: 14))
                                            .blinking()
                                        //                                            .skeleton(with: cart.inProgress, size: CGSize(width: CGFloat.infinity, height: 20), shape: .rounded(.radius(4, style: .circular)))
                                    } else {
                                        Text(element.priceString(currencyCode: cart.currencyCode, in: country.wrappedValue))
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
                    VStack(alignment: .leading) {
                        Text("checkout_order_summary_title".i18n)
                            .font(.custom("Poppins-Bold", size: 16))
                            .padding(.bottom, 16)
                        HStack {
                            TextField("checkout_order_coupon_code_hint".i18n, text: $coupon)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .onChange(of: coupon, perform: { newValue in
                                    if viewModel.isInvalidPromo {
                                        cart.resetPromo()
                                    }
                                })
                                .foregroundStyle(viewModel.isInvalidPromo ? Color.red : .black)
                                .overlay(RoundedRectangle(cornerRadius: 4)
                                    .stroke((viewModel.isInvalidPromo ? Color.red : .black)
                                        .opacity(coupon.count > 0 ? 1 : 0.15),
                                            lineWidth: 1)
                                )
                            AsyncButton(progressTint: .black) {
                                cart.apply(promoCode: coupon)
                                try? await viewModel.fetch()
                            } label: {
                                Text("cta_apply".i18n)
                                    .font(.custom("Roboto-Bold", size: 16))
                                    .foregroundStyle(Color.text.black80)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 32)
                            .disabled(coupon.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .clipShape(Capsule())
                            .overlay(RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.text.black20,
                                        lineWidth: 1)
                            )
                        }
                        if let promotion = cart.promotion {
                            if promotion.isValid  {
                                HStack(spacing: 4) {
                                    Image("checkmark-circle")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                    Text("checkout_order_coupon_valid".i18n)
                                        .font(.custom("Poppins-Regular", size: 12))
                                }
                                .foregroundStyle(Color.secondary.dark)
                            } else {
                                Text("checkout_order_coupon_invalid".i18n)
                                    .font(.custom("Poppins-Regular", size: 12))
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                    SummaryRow(title: "checkout_order_summary_price_before_fees",
                               amount: viewModel.cartTotal,
                               currency: cart.currencyCode,
                               blinking: cart.inProgress)
                        .padding(.bottom, 4)
                    if let fees = cart.fees {
                        ForEach(fees.indices, id: \.self) { index in
                            let fee = fees[index]
                            SummaryRow(title: fee.rateMilli != nil ? "\(fee.name) \(fee.rateMilli! / 1000)%%" : fee.name,
                                       amount: Double(fee.amountCents) / 100.00,
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
                               amount: viewModel.finalTotal,
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
                        try? await viewModel.prepareForPayment(in: country.wrappedValue)
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
                } else if let paymentLink {
                    AsyncButton(progressWidth: .infinity) {
                        try? await viewModel.prepareForPayment(in: country.wrappedValue)
                        showSafari = true
                    } label: {
                        HStack {
                            Text("checkout_proceed_cta".i18n)
                                .font(.custom("Roboto-Bold", size: 16))
                        }
                        .foregroundStyle(Color.background.white)
                        .frame(maxWidth: .infinity)
                    }
                    .sheet(isPresented: $showSafari) {
                        SafariView(url: URL(string: paymentLink.invoiceURL)!)
                    }
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
            try? await viewModel.prepareForPayment(in: country.wrappedValue)
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
            viewModel.onFetchedPaymentLink = { link in
                paymentLink = link
            }
            coupon = cart.promoCode ?? ""
            //            viewModel.preparePaymentSheet()
            Task {
                try? await viewModel.fetch()
                try? await viewModel.prepareForPayment(in: country.wrappedValue)
            }
            tabIsShown.wrappedValue = false
            Analytics.capture(.cartScreen)
        })
        .onChange(of: route) { newValue in
            guard let route = newValue.wrappedValue else {
                return
            }
            
            if route == .paymentSuccess {
                viewModel.state = .paymentSucceeded
                showSafari = false
                self.route.wrappedValue = nil
            }
            
            if route == .paymentFailed {
                viewModel.state = .paymentFailed
                showSafari = false
                self.route.wrappedValue = nil
            }
        }
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
    var amount: Double
    var allBold: Bool = false
    var currency: String
    var blinking: Bool = false
    @Environment(\.country) private var country
    
    var currencyText: String {
        return amount < 0 ? "-\(currency) " : "\(currency) "
    }
    
    var price: String {
        abs(amount).toPrice(currencyCode: currency,
                       localeIdentifier: country.wrappedValue.localeIdentifier,
                       dropCurrency: true)
    }
    
    var body: some View {
        HStack {
            Text(title.i18n)
                .font(allBold ? .custom("Poppins-SemiBold", size: 18) : .custom("Poppins-Medium", size: 16))
                .foregroundStyle(allBold ? Color.text.black100 : Color.text.black60)
            Spacer()
            HStack {
                Text(currencyText)
                    .font(.custom("Poppins-SemiBold", size: 16))
                + Text(price)
                    .font(.custom(allBold ? "Poppins-Bold" : "Poppins-Regular", size: 16))
            }
            .foregroundStyle(amount < 0 ? Color.secondary.dark : Color.text.black100)
            .blinking(when: blinking)
        }
    }
}

#Preview {
    CustomNavView {
        CheckoutView()
    }
}
