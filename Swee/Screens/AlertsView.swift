import SwiftUI

enum Routes {
    case profile
    case merchant(_ id: String)
}

struct AlertsView: View {
    protocol AlertType {
        var id: UUID { get }
        var title: String { get }
        var read: Bool { get set }
    }
    
    struct Action {
        let title: String
        let route: Routes
    }
    
    struct LocalCTA: AlertType {
        let id: UUID
        var read: Bool
        let title: String
        var image: Image?
        var description: String?
        var createdAt: Date
        var deeplink: String?
        var action: Action?
    }
    
    struct RedeemActivity: AlertType {
        let id: UUID
        var read: Bool
        let title: String
        let interval: TimeInterval
        let merchant: String
        var createdAt: Date
    }
    
    struct Announcement: AlertType {
        let id: UUID
        var read: Bool
        let title: String
        var description: String?
        var action: Action?
        let merchant: String
        var image: Image?
        var createdAt: Date
    }
    
    enum Alert: Identifiable {
        case localCTA(LocalCTA)
        case redeemActivity(RedeemActivity)
        case announcement(Announcement)
        
        var id: UUID {
            switch self {
            case .localCTA(let cta):
                return cta.id
            case .redeemActivity(let activity):
                return activity.id
            case .announcement(let announcement):
                return announcement.id
            }
        }
    }
    
    @Environment(\.tabIsShown) private var tabIsShown
    @Environment(\.currentTab) private var selectedTab
    @EnvironmentObject private var activeSession: ActiveSession
    @EnvironmentObject private var api: API
    
    @StateObject private var viewModel = AlertsViewModel()
    @State private var goToMerchant: Bool = false
//    @State private var alerts: [Alert] = [
//        .localCTA(.init(read: false, title: "Complete your profile and win 1 zoomoov ride", action: .init(title: "Complete profile", route: .profile))),
//        .redeemActivity(.init(read: true, title: "Jollyride active", interval: 8000, merchant: "Jollyfield")),
//        .announcement(.init(read: true, title: "Zoomoov is now on Swee", description: "We’re pleased to introduce that Zoomoov is now available in Swee", action: .init(title: "Explore", route: .merchant("Some id")), merchant: "Zoomoov", image: Image("alert-avatar"))),
//        .announcement(.init(read: true, title: "Celebrate your kids birthday at any of the Zoomoov location!", description: "50% off on all Zoomoov packages", merchant: "Zoomoov")),
//    ]
    
    func handle(route: Routes) -> Void {
        switch route {
        case .profile:
            selectedTab.wrappedValue = .profile
        case .merchant(_):
            goToMerchant = true
        }
    }
    
    func row(at index: Int) -> any View {
        switch viewModel.alerts[index] {
        case .localCTA(let cta):
            return AlertRow(alertId: cta.id,
                            index: index,
                            read: cta.read,
                            title: cta.title,
                            description: cta.description,
                            image: cta.image,
                            deeplink: cta.deeplink,
                            createdAt: cta.createdAt,
                            action: cta.action.toClosure({ route in
                handle(route: route)
            })) { alertId in
                viewModel.markAsRead(alertId)
            }
        case .redeemActivity(let activity):
            return AlertRow(alertId: activity.id,
                            index: index,
                            read: activity.read,
                            title: activity.title,
                            merchant: activity.merchant,
                            activityInterval: activity.interval,
                            createdAt: activity.createdAt) { alertId in
                viewModel.markAsRead(alertId)
            }
        case .announcement(let announcement):
            return AlertRow(alertId: announcement.id,
                            index: index,
                            read: announcement.read,
                            title: announcement.title,
                            description: announcement.description,
                            image: announcement.image,
                            merchant: announcement.merchant,
                            createdAt: announcement.createdAt,
                            action: announcement.action.toClosure({ route in
                handle(route: route)
            })) { alertId in
                viewModel.markAsRead(alertId)
            }
        }
    }
    
    private var emptyUI: some View {
        VStack(spacing: 0) {
            Spacer()
            Image("wallet-empty")
            Text("alerts_empty_title")
                .font(.custom("Poppins-SemiBold", size: 24))
                .padding(.horizontal, 16)
                .foregroundStyle(Color.text.black100)
                .multilineTextAlignment(.center)
                .padding(.top, 24)
            Text("alerts_empty_description")
                .font(.custom("Poppins-Regular", size: 14))
                .padding(.horizontal, 44)
                .foregroundStyle(Color.text.black60)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            Spacer()
            Spacer()
        }
    }
    
    private var loadingUI: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PurchaseRow.skeleton.equatable.view
                PurchaseRow.skeleton.equatable.view
                PurchaseRow.skeleton.equatable.view
                PurchaseRow.skeleton.equatable.view
            }
            .padding(.top, 48)
        }
    }
    
    var body: some View {
        CustomNavView {
            VStack {
                if !viewModel.loadedData {
                    loadingUI
                } else if viewModel.alerts.isEmpty {
                   emptyUI
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.alerts.indices, id: \.self) { index in
                                row(at: index).equatable.view
                            }
                            //                    CustomNavLink(isActive: $goToMerchant, destination: MerchantPageView()) {
                            //                    }
                        }
                        .padding(.bottom, activeSession.sessionIsActive ? 120 : 60)
                    }
                }
            }
            .onAppear {
                tabIsShown.wrappedValue = true
                viewModel.api = api
                Task {
                    try await viewModel.fetch()
                }
            }
            .customNavigationBackButtonHidden(true)
            .customNavLeadingItem {
                HStack(alignment: .center, spacing: 4) {
                    Text("alerts_title")
                        .font(.custom("Poppins-SemiBold", size: 20))
                    if viewModel.numberOfUnreadAlerts > 0 {
                        Text("(\(viewModel.numberOfUnreadAlerts))")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundStyle(Color.text.black60)
                    }
                }
            }
            .customNavTrailingItem {
                AsyncButton(progressTint: Color.primary.brand) {
                    try? await viewModel.markAllAsRead()
                    try? await viewModel.fetch()
                } label: {
                    Text("alerts_mark_all_as_read_cta")
                        .font(.custom("Poppins-Medium", size: 14))
                }
                .tint(Color.primary.brand)
                .hidden(viewModel.alerts.isEmpty)
            }
        }
    }
}

fileprivate extension Optional where Wrapped == AlertsView.Action {
    func toClosure(_ closure: @escaping (Routes) -> Void) -> AlertRow.Action? {
        switch self {
        case .none:
            return nil
        case .some(let action):
            return .init(title: action.title, closure: {
                closure(action.route)
            })
        }
    }
}

struct AlertRow: View {
    struct Action {
        let title: String
        let closure: () -> Void
    }
    
    @EnvironmentObject private var api: API
    @Environment(\.deeplink) private var deeplink
    var alertId: UUID
    var read: Bool
    var title: String
    var description: String?
    var image: Image?
    var linkURL: String?
    var merchant: String?
    @State var activityInterval: TimeInterval?
    var action: Action?
    var index: Int
    var createdAt: Date
    var onActionTriggered: (_ alertId: UUID) -> Void
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(alertId: UUID,
         index: Int,
         read: Bool = true,
         title: String,
         description: String? = nil,
         image: Image? = nil,
         deeplink: String? = nil,
         merchant: String? = nil,
         activityInterval: TimeInterval? = nil,
         createdAt: Date,
         action: Action? = nil,
         onActionTriggered: @escaping (_ alertId: UUID) -> Void) {
        self.alertId = alertId
        self.index = index
        self.title = title
        self.description = description
        self.image = image
        self.merchant = merchant
        self.activityInterval = activityInterval
        self.action = action
        self.read = read
        self.createdAt = createdAt
        self.linkURL = deeplink
        self.onActionTriggered = onActionTriggered
    }
    
    private var avatar: any View {
        ZStack {
            HStack(spacing: 0) {
                if !read {
                    Circle()
                        .foregroundStyle(Color.primary.brand)
                        .frame(width: 8, height: 8)
                        .padding(.trailing, 8)
                        .padding(.leading, -10)
                }
                if let image = image {
                    image
                } else if let merchant = merchant, !merchant.isEmpty {
                    Circle()
                        .foregroundStyle(Color.text.black20)
                        .frame(width: 48, height: 48)
                        .overlay {
                            Text(String(merchant.first!))
                                .foregroundStyle(Color.text.black60)
                                .font(.custom("Poppins-SemiBold", size: 20))
                        }
                } else {
                    Color.clear
                        .frame(width: 0, height: 48)
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if index != 0 {
                Rectangle()
                    .fill(Color.text.black10)
                    .frame(height: 1)
                    .padding(.leading, 20)
                    .padding(.trailing, -20)
                Spacer()
            }
            HStack(alignment: .top) {
                avatar.equatable.view
                    .padding(.leading, 8)
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.custom("Poppins-SemiBold", size: 14))
                    if let description = description {
                        Text(description)
                            .font(.custom("Poppins-Regular", size: 14))
                    }
                    if let unwrappedInterval = activityInterval {
                        HStack() {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.text.black10)
                                .frame(width: 4, height: 40)
                            
                            Text(unwrappedInterval.toString(includeSeconds: true))
                                .font(.custom("Poppins-Regular", size: 24)) +
                            Text(" Hrs")
                                .font(.custom("Poppins-Regular", size: 14))
                        }
                        .onReceive(timer, perform: { _ in
                            if unwrappedInterval > 0 {
                                activityInterval = unwrappedInterval - 1
                            }
                        })
                    }
                    if let action = action {
                        Button {
                            action.closure()
                        } label: {
                            Text(action.title)
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundStyle(Color.background.white)
                                .padding(.vertical, 5.5)
                                .padding(.horizontal, 14)
                                .background(Color.primary.brand)
                                .clipShape(Capsule())
                        }
                    }
                }
                Spacer()
                VStack(spacing: 0) {
                    Text(createdAt.timeElapsed)
                        .font(.custom("Poppins-Thin", size: 12))
                        .foregroundStyle(Color.text.black80)
                    Spacer()
                }
            }
            .padding(.vertical, 24)
            Spacer()
        }
        .onTapGesture {
//            if read { return }
            onActionTriggered(alertId)
            Task {
                do {
                    try await api.markAsReadAlert(with: alertId)
                    deeplink.wrappedValue = linkURL
                } catch {
                    // fail silently
                }
            }
        }
        .contentShape(Rectangle())
        .padding(.horizontal)
        .background(read ? .white : Color(hex: "#EDF3FF"))
    }
}


#Preview {
    AlertsView()
}

extension AlertRow: Skeletonable {
    static var skeleton: any View {
        VStack(alignment: .leading) {
            HStack {
                Color.white
                    .skeleton(with: true, shape: .circle)
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading) {
                    Text("")
                        .skeleton(with: true, shape: .rounded(.radius(12, style: .circular)))
                        .frame(width: 170, height: 20)
                    Text("")
                        .skeleton(with: true, shape: .rounded(.radius(12, style: .circular)))
                        .frame(width: 70, height: 10)
                    Text("")
                        .skeleton(with: true, shape: .rounded(.radius(12, style: .circular)))
                        .frame(width: 70, height: 10)
                }
                Spacer()
                Text("")
                    .skeleton(with: true, shape: .rounded(.radius(12, style: .circular)))
                    .frame(width: 40, height: 30)
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
    }
}

extension Color {
    
    static func random(randomOpacity: Bool = false) -> Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            opacity: randomOpacity ? .random(in: 0...1) : 1
        )
    }
}
