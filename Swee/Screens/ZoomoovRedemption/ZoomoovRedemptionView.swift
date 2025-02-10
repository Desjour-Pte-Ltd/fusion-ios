import SwiftUI

struct Ticket: Hashable {
    let merchant: String
    let quantity: Int
    let type: String
    let expirationDate: Date
    let colors: [Color]
}

enum ZoomoovRedemptionSteps: Equatable {
    case setup
    case redemptionQueue(Redemption)
    case error
    case completed
}

struct ZoomoovRedemptionModel {
    let purchaseId: UUID
    var totalQuantity: Int
    var qtyToRedeem: Int = 1
    var currentTicket: Int = 1
    let merchant: String
    let type: String
    let disclaimer: String?
    let productType: ProductType
}

extension ZoomoovRedemptionModel {
    static var empty: ZoomoovRedemptionModel {
        .init(purchaseId: .init(uuidString: "28910AFE-DB24-41D1-B0E1-6064D9C23083")!,
              totalQuantity: 0,
              qtyToRedeem: 0,
              currentTicket: 0,
              merchant: "",
              type: "",
              disclaimer: nil,
              productType: .coupon)
    }
}

struct ZoomoovRedemptionSetupView: View {
    @Binding var model: ZoomoovRedemptionModel
//    var purchase: Purchase
    var closure: () async throws -> Void
    
    var body: some View {
        VStack {
            Text("\(model.merchant) \(model.type)")
                .font(.custom("Poppins-SemiBold", size: 24))
            HStack {
                Text("redemption_coupon_set_qty".i18n(with: model.type.capitalized))
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundStyle(Color.text.black60)
                Spacer()
                HStack {
                    Button {
                        if model.qtyToRedeem == 1 {
                            return
                        }
                        model.qtyToRedeem -= 1
                    } label: {
                        Image("minus-circle")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                    .tint(model.qtyToRedeem == 1 ? Color.text.black20 : Color.secondary.brand)
                    Spacer()
                    Text("\(model.qtyToRedeem)")
                        .font(.custom("Poppins-Medium", size: 20))
                        .foregroundStyle(Color.secondary.brand)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        if model.qtyToRedeem == model.totalQuantity {
                            return
                        }
                        model.qtyToRedeem += 1
                    } label: {
                        Image("plus-circle")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                    .tint(model.qtyToRedeem == model.totalQuantity ? Color.text.black20 : Color.secondary.brand)
                }
                .frame(width: 100)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(Color.background.pale))
            
            VStack(alignment: .leading) {
                Text("redemption_set_qty_note_title")
                    .font(.custom("Poppins-Bold", size: 18))
                    .foregroundStyle(Color.text.black100)
                if let disclaimer = model.disclaimer {
                    Text(disclaimer)
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundStyle(Color.text.black80)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(Color.background.pale))
            .padding(.bottom, 37)
            AsyncButton(progressWidth: .infinity) {
                try? await closure()
            } label: {
                HStack {
                    Text("redemption_set_qty_cta")
                        .font(.custom("Roboto-Bold", size: 16))
                }
            }
            .foregroundStyle(Color.background.white)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(Color.secondary.brand)
            .clipShape(Capsule())
            .padding(.bottom, 16)
            //            .buttonStyle(EmptyStyle())
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct ZoomoovRedemptionView: View {
    @Environment(\.tabIsShown) private var tabIsShown
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var api: API
    @StateObject private var viewModel = ZoomoovRedemptionViewModel()
    @State var merchant: WalletMerchant
    
    @State var step: ZoomoovRedemptionSteps = .setup
    @State var currentRedemption: ZoomoovRedemptionModel = .empty
    
    @State var hidden = true
    
    var mainUI: some View {
        ForEach(viewModel.merchant.products, id: \.id) { product in
            VStack(alignment: .leading, spacing: 0) {
                Text(product.name.singularName)
                    .font(.custom("Poppins-SemiBold", size: 20))
                ForEach(product.purchases, id: \.id) { purchase in
                    TicketView(ticket: .init(merchant: viewModel.merchant.name,
                                             quantity: purchase.remainingValue,
                                             type: product.name,
                                             expirationDate: purchase.expiresAt,
                                             colors: merchant.bgColors))
                    .onTapGesture {
                        currentRedemption = .init(purchaseId: purchase.id,
                                                  totalQuantity: purchase.remainingValue,
                                                  merchant: viewModel.merchant.name,
                                                  type: product.name.singularName,
                                                  disclaimer: purchase.note,
                                                  productType: product.type)
                        hidden = false
                    }
                }
            }
        }
        .animation(.default, value: viewModel.merchant.products)
    }
    
    var loadingUI: some View {
        VStack(alignment: .leading) {
            Text("")
                .skeleton(with: true, shape: .rounded(.radius(12, style: .circular)))
                .frame(width: 160, height: 20)
            TicketView
                .skeleton.equatable.view
            TicketView
                .skeleton.equatable.view
        }
    }
    
    var body: some View {
        ZStack {
            if viewModel.showError {
                StateView.error {
                    try? await viewModel.fetch()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if viewModel.loadedData {
                           mainUI
                        } else {
                          loadingUI
                        }
                    }
                    .padding([.horizontal, .top], 16)
                }
                .onAppear(perform: {
                    viewModel.dismiss = dismiss
                    viewModel.api = api
                    viewModel.merchant = merchant
                    Task {
                        try? await viewModel.fetch()
                    }
                    tabIsShown.wrappedValue = false
                })
                .background(Color.background.pale)
            }
        }
        .customNavigationTitle(viewModel.merchant.name)
        .customBottomSheet(hidden: $hidden) {
            ZoomoovBottomSheet(model: $currentRedemption) {
                Task {
                    try? await viewModel.fetch()
                }
                hidden = true
            }
        }
        .onChange(of: hidden) { newValue in
            Task {
                try? await viewModel.fetch()
            }
        }
    }
}

//#Preview {
//    CustomNavView {
//        ZoomoovRedemptionView(tickets: [
//            .init(merchant: "Zoomoov", quantity: 12, description: "Rides", type: "Rides", expirationDate: Date(), colors: Color.gradient.primary),
//            .init(merchant: "Zoomoov", quantity: 1, description: "Masks", type: "Mask", expirationDate: Date(), colors: [Color(hex: "#EC048A"), Color(hex: "#F0971C")])
//        ]
//        )
//    }
//}
