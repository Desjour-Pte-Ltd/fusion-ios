import SwiftUI
import Combine
import SDWebImageSwiftUI

enum Tabs: Int, CaseIterable, Identifiable {
    
    case home = 0
    case myWallet
    case alerts
    case profile
    
    @ViewBuilder
    var screen: some View {
//        VStack {}
        switch self {
        case .home:
            HomeView()
        case .myWallet:
            MyWalletView()
        case .alerts:
            AlertsView()
        case .profile:
            ProfileView()
        }
    }
    
    var title: String{
        switch self {
        case .home:
            return "Home"
        case .myWallet:
            return "Purchases"
        case .alerts:
            return "Alerts"
        case .profile:
            return "Profile"
        }
    }
    
    var iconName: String{
        switch self {
        case .home:
            return "home"
        case .myWallet:
            return "purchases"
        case .alerts:
            return "alerts"
        case .profile:
            return "profile"
        }
    }
    
    var id: Tabs { self }
}

struct MainView: View {
    @EnvironmentObject private var api: API
    @Environment(\.route) private var route
    @StateObject var activeSession = ActiveSession(refreshFrequencyInMin: 5)
    @State private var selectedTab: Tabs = .home
    @State private var tabIsShown = true
    @State private var cancellables = Set<AnyCancellable>()
    @State private var goToActiveSession = false
    
    func TabItem(imageName: String, title: String, isActive: Bool) -> some View {
        VStack {
            Image(isActive ? "\(imageName)"+"-active" : imageName)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(isActive ? Color.primary.brand : Color.text.black60)
                .frame(width: 24, height: 24)
            Text(title)
                .font(isActive ? .custom("Poppins-Medium", size: 12) : .custom("Poppins-SemiBold", size: 12))
                .foregroundStyle(isActive ? Color.primary.brand : Color.text.black60)
        }
        .animation(.default, value: selectedTab)
        .padding(.top, 7)
        .frame(maxWidth: 100, maxHeight: 60)
    }
    
    var activeSessionUI: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(activeSession.session?.merchantName)
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundStyle(LinearGradient(colors: Color.gradient.primary, startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text("In progress")
                        .font(.custom("Poppins-SemiBold", size: 12))
                        .foregroundStyle(Color.white)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(Color.secondary.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Spacer()
                }
//                HStack {
//                    Text(activeSession.session?.hoursPassed)
//                        .font(.custom("Poppins-Bold", size: 31))
//                        .foregroundStyle(Color.secondary.brand)
//                    Text("Hours passed")
//                        .font(.custom("Poppins-Regular", size: 24))
//                    Spacer()
//                }
//                Text("Total package left : \(activeSession.session!.availableTime) Hours")
//                    .font(.custom("Poppins-SemiBold", size: 14))
//                    .foregroundStyle(Color.text.black40)
            }
            Image("arrow-right")
                .resizable()
                .frame(width: 32, height: 32)
                .tint(Color.black)
        }
        .contentShape(.rect)
        .onTapGesture {
            selectedTab = .myWallet
            goToActiveSession = true
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .padding(14)
        .background(.ultraThickMaterial)
        .compositingGroup()
        .shadow(color: .black.opacity(0.15), radius: 2, y: -2)
    }
    
    private func handle(route: Binding<Route?>) {
        guard let route = route.wrappedValue else {
            return
        }
        switch route {
        case .package(_), .merchant(_):
            selectedTab = .home
        case .profile:
            selectedTab = .profile
            self.route.wrappedValue = nil
        case .alerts:
            selectedTab = .alerts
            self.route.wrappedValue = nil
        case .wallet:
            selectedTab = .myWallet
            self.route.wrappedValue = nil
        case .myActivity:
            selectedTab = .myWallet
        case .referral:
            selectedTab = .home
        case .activeSession:
            selectedTab = .myWallet
            if activeSession.sessionIsActive {
                goToActiveSession = true
                self.route.wrappedValue = nil
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                    if activeSession.sessionIsActive {
                        goToActiveSession = true
                        self.route.wrappedValue = nil
                    }
                })
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                ForEach(Tabs.allCases) { tab in
                    tab.screen
                        .tag(tab as Tabs?)
                }
            }
            ZStack {
                if tabIsShown {
                    VStack(spacing: 0) {
                        if activeSession.sessionIsActive {
                            activeSessionUI
                        }
                        HStack{
                            Spacer()
                            ForEach((Tabs.allCases), id: \.self){ item in
                                Button{
                                    selectedTab = item
                                } label: {
                                    TabItem(imageName: item.iconName, title: item.title, isActive: (selectedTab == item))
                                }
                                .buttonStyle(EmptyStyle())
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .background(.ultraThickMaterial)
                        .compositingGroup()
                        .shadow(color: .black.opacity(activeSession.sessionIsActive ? 0.2 : 0.15), radius: activeSession.sessionIsActive ? 0.5 : 2, y: activeSession.sessionIsActive ? -0.5 : -2)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onChange(of: route, perform: { newValue in
                handle(route: route)
            })
            .onAppear(perform: {
                //  NOTE: Uncomment to keep the images loading indefinately
//                SDImageCachesManager.shared.caches = []
//                SDWebImageManager.defaultImageCache = SDImageCachesManager.shared
//                handle(route: route)
            })
            .animation(.snappy(duration: 0.2), value: tabIsShown)
            .animation(.snappy(duration: 0.2), value: activeSession.sessionIsActive)
        }
        .environment(\.tabIsShown, $tabIsShown)
        .environment(\.currentTab, $selectedTab)
        .environment(\.goToActiveSession, $goToActiveSession)
        .environmentObject(activeSession)
    }
}

extension Session {
    var hoursPassed: String {
        guard let startedAt = startedAt else {
            return "--:--"
        }
        let interval = Date.now.timeIntervalSince(startedAt)
           
           let hours = Int(interval) / 3600
           let minutes = (Int(interval) % 3600) / 60
           
           let formattedString = String(format: "%02d:%02d", hours, minutes)
           
           return formattedString
    }
    
    var availableTime: String {
        if let remainingTime = remainingTimeMinutes {
            return Double(remainingTime * 60).toString()
        }
        
        return "--:--"
    }
}

#Preview {
    MainView()
}
