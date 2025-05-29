import SwiftUI

struct WalletMerchant: Equatable {
    let id: UUID
    let name: String
    let photoURL: URL?
    let bgColors: [Color]
    let purchaseSummary: String
    let products: [PurchaseProduct]
    let productsType: ProductType?
    var activeSession: Session?
}

extension WalletMerchant {
    static var empty: Self {
        .init(id: .init(uuidString: "28910AFE-DB24-41D1-B0E1-6064D9C23083")!,
              name: "",
              photoURL: nil,
              bgColors: [],
              purchaseSummary: "",
              products: [],
              productsType: nil,
              activeSession: nil)
    }
}

extension WalletMerchantModel: RawModelConvertable {
    func toLocal() -> WalletMerchant {
        let colors = merchantBackgroundColors ?? []
        let products = products ?? []
        return .init(id: merchantID,
                     name: merchantName,
                     photoURL: merchantPhotoURL,
                     bgColors: colors.map { Color(hex: $0) },
                     purchaseSummary: purchaseSummary,
                     products: products.map { $0.toLocal() },
                     productsType: productType,
                     activeSession: activeSession?.toLocal())
    }
}
