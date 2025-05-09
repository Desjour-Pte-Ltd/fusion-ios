import SwiftUI
import Combine
import StripePaymentSheet

class CheckoutViewModel: ObservableObject {
    enum State {
        case loaded
        case empty
        case error
        case paymentSucceeded
        case paymentFailed
    }
    
    var cart: Cart = Cart()
    private var loadedData = false
    private var showError = false
    private var cancellables = Set<AnyCancellable>()
    @Published private(set) var state: State = .loaded
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    @Environment(\.openURL) private var openURL
    @Published var readyForCheckout: Bool = false
    
    var onFetchedPaymentLink: ((PaymentLink) -> Void)?
    
    func onPaymentCompletion(result: PaymentSheetResult) {
        self.paymentResult = result
        print("payment result =====", result)
        switch result {
        case .completed:
            state = .paymentSucceeded
        case .canceled:
            print("cancelled payment")
        case .failed:
            state = .paymentFailed
        }
    }
    
    var quantity: Int {
        return cart.quantity
    }
    
    var cartTotal: Double {
        return Double(cart.priceCents / 100)
    }
    
    var finalTotal: Double {
        return Double(cart.totalPriceCents / 100)
    }
    
    func fetch() async throws {
        self.cart.$packages.sink { items in
            Task {
                await MainActor.run { [weak self] in
                    self?.state = items.isEmpty ? .empty : .loaded
                }
            }
        }
        .store(in: &cancellables)
        do {
            try await cart.refresh()
            await MainActor.run {
                showError = false
                loadedData = true
            }
        } catch {
            await MainActor.run {
                state = .error
                showError = true
            }
        }
    }
    
    func decreaseQuantity(for item: CartItem) async {
        guard cart.packages.contains(where: { $0.id == item.id }),
              let packageId = item.packageId else {
            return
        }
        
        if item.quantity == 1 {
            try? await cart.deletePackage(packageId)
            
            return
        }
        
        Task {
            try? await cart.changeQuantity(packageId, quantity: item.quantity - 1)
        }
    }
    
    func increaseQuantity(for item: CartItem) {
        guard let packageId = item.packageId else {
            return
        }
        Task {
            try? await cart.changeQuantity(packageId, quantity: item.quantity + 1)
        }
    }
    
    func prepareForPayment(in country: Country) async throws {
        if cart.packages.isEmpty {
            return
        }
        do {
            let order = try await cart.checkout()
            
            if order.status == .completed {
                await MainActor.run {
                    state = .paymentSucceeded
                }
                return
            }
            
            if country == .Singapore || country == .Philippines {
                guard let paymentIntent = order.paymentIntent else {
                    throw LocalError(message: "Missing payment intent data")
                }
                
                STPAPIClient.shared.publishableKey = Strings.stripePublishableKey
                // MARK: Create a PaymentSheet instance
                
                await MainActor.run {
                    var configuration = PaymentSheet.Configuration()
                    configuration.returnURL = Strings.stripeReturnURL
                    configuration.applePay = .init(
                        merchantId: Strings.stripeMerchantId,
                        merchantCountryCode: "SG"
                    )
                    
                    configuration.merchantDisplayName = Strings.stripeMerchantName
                    configuration.customer = .init(id: paymentIntent.customerId, ephemeralKeySecret: paymentIntent.ephemeralKey)
                    configuration.appearance = paymentSheetAppearance()
                    self.paymentSheet = PaymentSheet(paymentIntentClientSecret: paymentIntent.clientSecret,
                                                     configuration: configuration)
                }
            }
            
            if country == .Indonesia {
                guard let paymentLink = order.paymentLink, let paymentURL = URL(string: paymentLink.invoiceURL) else {
                    throw LocalError(message: "Missing payment link data")
                }
                
                onFetchedPaymentLink?(paymentLink)
            }
        } catch {
            await MainActor.run {
                state = .error
            }
        }
    }
    
    private func paymentSheetAppearance() -> PaymentSheet.Appearance {
        var appearance = PaymentSheet.Appearance()
        appearance.font.base = UIFont(name: "Poppins-Regular", size: UIFont.systemFontSize)!
        appearance.cornerRadius = 12
        appearance.shadow = .disabled
        appearance.borderWidth = 0.5
        appearance.colors.background = .white
        appearance.colors.primary = UIColor(Color.primary.brand)
        appearance.colors.textSecondary = .black
        appearance.colors.componentPlaceholderText = UIColor(red: 115/255, green: 117/255, blue: 123/255, alpha: 1)
        appearance.colors.componentText = .black
        appearance.colors.componentBorder = .clear
        appearance.colors.componentDivider = UIColor(red: 195/255, green: 213/255, blue: 200/255, alpha: 1)
        appearance.colors.componentBackground = UIColor(red: 243/255, green: 248/255, blue: 250/247, alpha: 1)
        appearance.primaryButton.cornerRadius = 20
        
        return appearance
    }
}

extension PaymentSheet {
    static var empty: PaymentSheet {
        return PaymentSheet(paymentIntentClientSecret: "", configuration: .init())
    }
}
