import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import GoogleSignIn
import StripePaymentSheet

final class AppRootManager: ObservableObject {
    
    @Published var currentRoot: AppRoots = .splash
    
    enum AppRoots {
        case splash
        case onboarding
        case authentication
        case main
    }
}

enum Route: Hashable {
    case profile
    case alerts
    case wallet
    case myActivity
    case referral
    case package(UUID)
    case merchant(UUID)
    case activeSession
}

@main
struct SweeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appRootManager = AppRootManager()
    @StateObject var api = API()
    @StateObject var cart = Cart()
    @StateObject var locationManager = LocationManager()
    @StateObject var pushNotificationManager = PushNotificationManager()
    @State var route: Route?
    @State private var delayedRoute: Route?
    @State var fcmToken: String?
    @State var deeplink: String?
    
    func handleURL(_ url: URL) {
        let stripeHandled = StripeAPI.handleURLCallback(with: url)
        guard !stripeHandled else {
            return
        }
        if url.scheme == "com.zoomoov.greenapp", let host = url.host {
            var newRoute: Route = .profile
            let uuidString = url.absoluteString.components(separatedBy: "=").last
            switch host {
            case "profile":
                newRoute = .profile
            case "alerts":
                newRoute = .alerts
            case "wallet":
                newRoute = .wallet
            case "activity":
                newRoute = .myActivity
            case "referral":
                newRoute = .referral
            case "activesession":
                newRoute = .activeSession
            case "product":
                guard let uuidString, let uuid = UUID(uuidString: String(uuidString.uppercased())) else { return }
                newRoute = .package(uuid)
            case "merchant":
                guard let uuidString, let uuid = UUID(uuidString: String(uuidString.uppercased())) else { return }
                newRoute = .merchant(uuid)
            case "stripe-redirect":
                return
            default:
                return
            }
            
            if appRootManager.currentRoot != .main {
                delayedRoute = newRoute
            } else {
                route = newRoute
            }
        }
    }
    
    private func process(deeplink: String?) {
        if let deeplink = deeplink,
            let url = URL(string: deeplink) {
            DispatchQueue.main.async {
                handleURL(url)
            }
            self.deeplink = nil
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch appRootManager.currentRoot {
                case .splash:
                    SplashView()
                case .onboarding:
                    OnboardingView()
                case .authentication:
                    AuthView()
                case .main:
                    MainView()
                }
            }
            .onAppear(perform: {
                cart.api = api
            })
            .onOpenURL(perform: { url in
                handleURL(url)
            })
            .onChange(of: delegate.fcmToken, perform: { newValue in
                fcmToken = newValue
                guard let newValue else {
                    return
                }
                Task {
                    try? await api.savePushToken(newValue)
                }
            })
            .onChange(of: delegate.deeplink, perform: { newValue in
                process(deeplink: delegate.deeplink)
            })
            .onChange(of: deeplink, perform: { newValue in
                process(deeplink: deeplink)
            })
            .onChange(of: appRootManager.currentRoot, perform: { newValue in
                if newValue == .main {
                    route = delayedRoute
                    delayedRoute = nil
                }
            })
            .onChange(of: api.sendToAuth, perform: { newValue in
                if newValue {
                    cart.reset()
                    appRootManager.currentRoot = .authentication
                }
            })
            .environment(\.route, $route)
            .environment(\.deeplink, $deeplink)
            .environment(\.fcmToken, $fcmToken)
            .environmentObject(appRootManager)
            .environmentObject(api)
            .environmentObject(cart)
            .environmentObject(locationManager)
            .environmentObject(pushNotificationManager)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate, ObservableObject {
    
    @Published var fcmToken: String?
    @Published var deeplink: String?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        application.registerForRemoteNotifications()
        return true
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("fcmToken =====", fcmToken)
        self.fcmToken = fcmToken
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification notification: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(notification) {
            completionHandler(.noData)
            return
        }
        // This notification is not auth related; it should be handled separately.
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
      return GIDSignIn.sharedInstance.handle(url)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        if let deeplink = response.notification.request.content.userInfo["deeplink"] as? String {
            self.deeplink = deeplink
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.badge, .banner, .list, .sound]
    }
}
