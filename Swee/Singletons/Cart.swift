import Foundation
import Combine

struct CartItem: Codable, Identifiable {
    let id: UUID
    let packageId: UUID?
    let packageDetails: PackageModel?
    let quantity: Int
    let totalPriceCents: Int
    @DecodableDate var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case packageId = "package_id"
        case packageDetails = "package_details"
        case quantity
        case totalPriceCents = "total_price_cents"
        case createdAt = "created_at"
    }
    
    var pricePerItem: Int {
        return quantity > 0 ? totalPriceCents / quantity : 0
    }
}

struct Promotion: Codable {
    let isValid: Bool
    let promoCode: String
    
    enum CodingKeys: String, CodingKey {
        case isValid = "is_valid"
        case promoCode = "promo_code"
    }
}

struct CartModel: Codable {
    let id: UUID
    let items: [CartItem]
    let quantity: Int
    let currencyCode: String
    let priceCents: Int64
    let totalPriceCents: Int64
    let fees: [FeeModel]?
    let promotion: Promotion?
    @DecodableDate var createdAt: Date
    @DecodableDate var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case items
        case quantity
        case currencyCode = "currency_code"
        case priceCents = "price_cents"
        case totalPriceCents = "total_price_cents"
        case fees
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case promotion
    }
}

struct FeeModel: Codable {
    let name: String
    let amountCents: Int64
    let rateMilli: Int64?
    
    enum CodingKeys: String, CodingKey {
        case name
        case amountCents = "amount_cents"
        case rateMilli = "rate_milli"
    }
}

class Cart: ObservableObject {
    @Published var packages: [CartItem] = []
    var api = API()
    private let operationQueue: OperationQueue = OperationQueue()
    private var operations: [String: BlockOperation] = [:]
    var quantity: Int {
        return packages.reduce(0) { acc, item in
            return acc + item.quantity
        }
    }

    @Published private(set) var currencyCode: String = "SGD"
    @Published private(set) var priceCents: Int64 = 0
    @Published private(set) var totalPriceCents: Int64 = 0
    @Published private(set) var fees: [FeeModel]? = []
    @Published private(set) var updatedAt: Date = .now
    @Published private(set) var promoCode: String?
    @Published private(set) var promotion: Promotion?
    
    private var id: UUID = .init()
    var inProgress = false
    var stopRefresh = false
    var refreshingPackageID: UUID? = nil
    var debounceTimer: Timer?
    
    func apply(promoCode: String?) {
        self.promoCode = promoCode
    }
    
    func refresh() async throws {
        operationQueue.maxConcurrentOperationCount = 1
        let cart = try await self.api.latestCart(promoCode: promoCode)
        await MainActor.run {
            if stopRefresh {
                return
            }
//            if let timer = debounceTimer, timer.isValid {
//                return
//            }
            id = cart.id
            packages = cart.items
            currencyCode = cart.currencyCode
            priceCents = cart.priceCents
            totalPriceCents = cart.totalPriceCents
            fees = cart.fees
            updatedAt = cart.updatedAt
            promotion = cart.promotion
            if let validCode = cart.promotion?.isValid, !validCode {
                promoCode = nil
            }
            inProgress = false
            refreshingPackageID = nil
        }
    }
    
    func resetPromo() {
        promoCode = nil
        promotion = nil
    }
    
    func reset() {
        packages = []
        inProgress = false
        priceCents = 0
        totalPriceCents = 0
        fees = []
        promoCode = nil
        promotion = nil
    }
    
    func addPackage(_ id: UUID, quantity: Int = 1) async throws {
        guard !packages.contains(where: { item in
            item.packageId == id
        }) else {
            return
        }
        inProgress = true
        do {
            let item = try await self.api.addPackageToCart(id, quantity: quantity)
            await MainActor.run {
                self.packages.append(item)
            }
            Task {
                try? await refresh()
            }
        } catch {
            inProgress = false
        }
    }
    
    func changeQuantity(_ packageId: UUID, quantity: Int) async throws {
        refreshingPackageID = packageId
        inProgress = true
        let oldItems = packages
        guard let index = packages.firstIndex(where: { $0.packageId == packageId }) else {
            try await addPackage(packageId, quantity: quantity)
            return
        }
        let item = packages[index]
        await MainActor.run {
            let pricePerItem = item.pricePerItem
            packages[index] = .init(id: item.id, packageId: item.packageId, packageDetails: item.packageDetails, quantity: quantity, totalPriceCents: quantity * pricePerItem, createdAt: item.createdAt)
            stopRefresh = true
        }
        
        //        let operation = BlockOperation()
        //        operation.addExecutionBlock {
//        await MainActor.run {
            //            debounceTimer?.invalidate()
            //            debounceTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            //                Task {
            do {
                try await self.api.changeQuantityInCart(for: item.id, quantity: quantity)
                await MainActor.run {
                    self.stopRefresh = false
                    Task {
                        self.inProgress = false
                        try? await self.refresh()
                    }
                }
                //                    }
            } catch {
                await MainActor.run {
                    self.inProgress = false
                    self.packages = oldItems
                }
            }
            //                }
//            }
//        }
        
//        operations[packageId.uuidString.lowercased()] = operation
//        
//        operationQueue.addOperation(operation)
    }
    
    func deletePackage(_ packageId: UUID) async throws {
        guard let index = packages.firstIndex(where: { $0.packageId == packageId }) else {
            return
        }
        inProgress = true
        let item = packages[index]
        self.stopRefresh = true
        do {
            try await api.deletePackageFromCart(item.id)
            await MainActor.run {
                let _ = packages.remove(at: index)
                self.stopRefresh = false
                Task {
                    self.inProgress = false
                    try? await self.refresh()
                }
            }
        } catch {
            inProgress = false
        }
    }
    
    func checkout() async throws -> Order {
        do {
            // @todo handle all order states
            let order = try await api.createOrder(for: id,
                                                  promoCode: (promotion?.isValid ?? false) ? promoCode : nil)
            if order.status == .completed {
                print("successful order ====", order)
                await MainActor.run {
                    reset()
                }
            }
            return order.toLocal()
        } catch {
            print("checkout error", error)
            throw error
        }
        
    }

    func quantity(for package: Package) -> Int {
        guard let item = packages.first(where: { $0.packageId == package.id }) else {
            return 0
        }
        
        return item.quantity
    }
}
