import Foundation
import SwiftUI
import SDWebImageSwiftUI
import SDWebImage
import SkeletonUI

struct HomeView: View {
    @EnvironmentObject private var api: API
    @EnvironmentObject private var cart: Cart
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var pushNotificationManager: PushNotificationManager
    @EnvironmentObject private var activeSession: ActiveSession
    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.tabIsShown) private var tabIsShown
    @Environment(\.route) private var route
    @State private var hideBottomSheet: Bool = true
    @State private var navView: UINavigationController? = nil
    @State private var goToPackage = false
    @State private var goToMerchant = false
    @State private var deepLinkPackage: Package?
    @State private var deepLinkMerchantId: UUID?
    @State private var showShareSheet: Bool = false
    @State private var shareSheetText: String = ""
    @State private var showAlert = false
    @State private var alertData: CustomAlert.Data = .init(title: "referral_alert_success_title",
                                                           message: "referral_alert_success_message",
                                                           buttonTitle: "referral_alert_success_cta",
                                                           showConfetti: true,
                                                           style: .defaultStyle(width: 260,
                                                                                mainButtonColor: Color.primary.brand,
                                                                                cornerRadius: 12,
                                                                                image: Image("star")),
                                                           action: .init(closure: {}))
    
    func sectionView(for section: HomeViewModel.Section) -> any View {
        switch section.content {
        case .bannerCarousel(let banners):
            return BannersCarousel(banners: banners)
        case .packages(let packages):
            return PackagesCarousel(model: PackageCarouselModel(sectionID: section.id, title: section.title ?? "", packages: packages))
        case .merchants(let merchants):
            return MerchantList(model: .init(title: section.title ?? "", merchants: merchants))
                .padding(.horizontal, 16)
        case .bannerStatic(let banners):
            if banners.isEmpty {
                return EmptyView()
            }
            return ReferalCard(banner: banners[0])
                .padding(.horizontal, 16)
        }
    }
    
    var skeletonUI: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                BannersView
                    .skeleton.equatable.view
                PackagesCarousel
                    .skeleton.equatable.view
                PackagesCarousel
                    .skeleton.equatable.view
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 20)
            .padding(.leading, 16)
        }
        .introspect(.scrollView, on: .iOS(.v15, .v16, .v17, .v18), customize: { scrollView in
            scrollView.isUserInteractionEnabled = false
        })
    }
    
    var mainUI: some View {
        ScrollView {
            VStack(spacing: 16) {
                //                Button("Crash") {
                //                  fatalError("Crash was triggered")
                //                }
                ForEach(viewModel.sections, id: \.id) { section in
                    sectionView(for: section).equatable.view
                }
            }
            .padding(.vertical, 20)
            .padding(.bottom, activeSession.sessionIsActive ? 160 : 100)
        }
        .refreshable(action: {
            try? await viewModel.fetch()
        })
        .ignoresSafeArea()
    }
    
    var body: some View {
        CustomNavView {
            ZStack {
                if let package = deepLinkPackage {
                    CustomNavLink(isActive: $goToPackage, destination: PackageDetailView(package: package))
                }
                if let deepLinkMerchantId, let merchant = viewModel.merchant(for: deepLinkMerchantId) {
                    CustomNavLink(isActive: $goToMerchant, destination: MerchantPageView(merchant: merchant))
                }
                VStack {
                    if viewModel.showError {
                        StateView.error {
                            try? await viewModel.fetch()
                        }
                    } else if viewModel.sections.isEmpty {
                        skeletonUI
                    } else {
                        mainUI
                    }
                }
                .onChange(of: hideBottomSheet, perform: { newValue in
                    tabIsShown.wrappedValue = hideBottomSheet
                })
                .onAppear(perform: {
                    viewModel.api = api
                    viewModel.cart = cart
                    Task {
                        if pushNotificationManager.shouldAsk, await !pushNotificationManager.hasPermissions() {
                            pushNotificationManager.shouldAsk = false // we only want to ask once per app launch
                            await MainActor.run() {
                                hideBottomSheet = false
                            }
                        }
                    }
                    Task {
                        try? await viewModel.fetch()
                    }
                    tabIsShown.wrappedValue = true
                    if let freshReferral = api.user?.freshReferral, freshReferral {
                        Task {
                            await MainActor.run() {
                                showAlert = true
                                api.user?.freshReferral = false
                            }
                        }
                    }
                    locationManager.checkLocationAuthorization()
                    // @todo set region
                    Analytics.capture(.homeScreen(.init(region: .Singapore)))
                })
                .sheet(isPresented: $showShareSheet, content: {
                    ShareSheet(text: shareSheetText)
                })
                .customNavigationBackButtonHidden(true)
                .customNavLeadingItem {
                    LogoNavItem()
                }
                .customNavTrailingItem {
                    CartButton()
                }
                .customBottomSheet(hidden: $hideBottomSheet) {
                    NotificationUpsell(hide: $hideBottomSheet)
                }
                .customAlert(isActive: $showAlert, data: alertData)
            }
        }
        .onChange(of: showAlert, perform: { newValue in
            tabIsShown.wrappedValue = !showAlert
        })
        .onChange(of: route) { newValue in
            guard let route = route.wrappedValue else {
                return
            }
            switch route {
            case .package(let id):
                Task {
                    do {
                        let package = try await viewModel.package(for: id)
                        await MainActor.run {
                            deepLinkPackage = package
                            goToPackage = true
                        }
                    } catch {
                        // fail silently
                    }
                }
                self.route.wrappedValue = nil
            case .merchant(let merchantId):
                deepLinkMerchantId = merchantId
                goToMerchant = true
                self.route.wrappedValue = nil
            case .referral:
                Task {
                    do {
                        let referralCode = try await viewModel.getReferralCode().referralCode
                        
                        shareSheetText = "referral_share_sheet_text".i18n(with: referralCode, referralCode)
                        
                        await MainActor.run {
                            showShareSheet = true
                        }
                    } catch {
                        // fail silently
                    }
                }
                self.route.wrappedValue = nil
            default:
                return
            }
        }
        .environment(\.navView, $navView)
        .introspect(.navigationView(style: .stack), on: .iOS(.v15, .v16, .v17, .v18), customize: { navView in
            self.navView = navView
            navView.tabBarController?.tabBar.isHidden = true
        })
    }
}

#Preview(body: {
    ScrollView {
        VStack(spacing: 30) {
            BannersView
                .skeleton.equatable.view
            PackagesCarousel
                .skeleton.equatable.view
            PackagesCarousel
                .skeleton.equatable.view
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
    }
})

struct MerchantListModel {
    let title: String
    let merchants: [Merchant]
}

struct MerchantList: View {
    @State var model: MerchantListModel
    
    var body: some View {
        VStack {
            Text(model.title)
                .textStyle(HomeRowTitleStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: 8) {
                ForEach(model.merchants.indices, id: \.self) { index in
                    MerchantCard(merchant: model.merchants[index])
                }
            }
        }
    }
}

struct HomeRowTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.custom("Poppins-SemiBold", size: 20))
    }
}

#Preview {
    HomeView()
        .environmentObject(API())
}
