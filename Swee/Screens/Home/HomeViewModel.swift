import SwiftUI
import Combine

enum HomeSectionContent {
    case bannerCarousel([Banner])
    case packages([Package])
    case merchants([Merchant])
    case bannerStatic([Banner])
}

class HomeViewModel: ObservableObject {
    struct Section {
        let id: UUID
        var title: String?
        let content: HomeSectionContent
    }
    
    var api: API = API()
    var cart: Cart = Cart()
    @State private var loadedData = false
    @Published var showError = false
    @Published var sections: [Section] = []
    
    func fetch() async throws {
        guard !loadedData else {
            return
        }
        do {
            let sectionsModels = try await api.homeSections()
            loadedData = true
            let sections: [Section] = sectionsModels.map { model in
                switch model.type {
                case .bannerCarousel:
                        .init(id: model.id, title: model.title, content: .bannerCarousel(model.banners.toLocal()))
                case .packageCarousel:
                        .init(id: model.id, title: model.title, content: .packages(model.packages.toLocal()))
                case .merchantList:
                        .init(id: model.id, title: model.title, content: .merchants(model.merchants.toLocal()))
                case .bannerStatic:
                        .init(id: model.id, content: .bannerStatic(model.banners.toLocal()))
                }
            }
            await MainActor.run {
                showError = false
                self.sections = sections
            }
            try? await cart.refresh()
        } catch {
            await MainActor.run {
                showError = true
            }
        }
    }
    
    func merchant(for id: UUID) -> Merchant? {
        var merchant: Merchant? = nil
        sections.forEach({ section in
            if case .merchants(let merchants) = section.content {
                merchant = merchants.first { merchant in
                    merchant.id == id
                }
            }
        })
        
        return merchant
    }
    
    func package(for id: UUID) async throws -> Package {
        var package: Package? = nil
        sections.forEach { section in
            if case .packages(let packages) = section.content {
                package = packages.first(where: { $0.id == id } )
            }
        }
        
        if let package = package {
            return package
        } else {
            return try await api.packageDetails(for: id).toLocal()
        }
    }
    
    func getReferralCode() async throws -> UserReferralCodeModel {
        try await api.referralCode()
    }
}

extension Optional where Wrapped: Collection, Wrapped.Element: RawModelConvertable {
    func toLocal() -> [Wrapped.Element.LocalModel] {
        switch self {
        case .none:
            return []
        case .some(let items):
            return items.toLocal()
        }
    }
}

extension Collection where Element: RawModelConvertable {
    func toLocal() -> [Element.LocalModel] {
        map { $0.toLocal() }
    }
}
