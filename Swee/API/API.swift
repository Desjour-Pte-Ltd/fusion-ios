import Foundation
import CoreLocation
import SwiftUI
import Alamofire

class API: ObservableObject {
    @Published var user: User?
    @Published var sendToAuth: Bool = false
    
    enum SignInResponse: Codable {
        case loggedIn
        case withoutName
    }
    
    @discardableResult
    func signIn(with token: String) async throws -> SignInResponse {
        UserDefaults.standard.setValue(token, forKey: Keys.authToken)
        
        print("token =====", token)
        
        let url = "/users/me?token=" + token
        
        return try await request(with: url, reauthenticate: false) { data, response in
            if response.statusCode == 404 {
                let convertedString = String(data: data, encoding: String.Encoding.utf8)
                if let stringResponse = convertedString, stringResponse.contains("DATA_NOT_FOUND") {
                    return .withoutName
                } else {
                    throw APIError.wrongCode
                }
            }
            
            if response.statusCode == 403 {
                do {
                    let token = try await Authentication().reauthenticate()
                    return try await self.signIn(with: token)
                } catch {
                    throw LocalError(message: "api_error_reauthentication".i18n)
                }
            }
            
            guard response.statusCode == 200 else {
                throw APIError.wrongCode
            }
            
            do {
                let user = try JSONDecoder().decode(User.self, from: data)
                await MainActor.run {
                    self.user = user
                }
                return .loggedIn
            } catch {
                throw APIError.decodingError
            }
        }
    }
    
    func signOut() async {
        UserDefaults.standard.removeObject(forKey: Keys.authToken)
        //        cart.reset()
        try? await Authentication().logout()
    }
    
    func completeUser(with name: String, and referralCode: String? = nil) async throws {
        guard let token = UserDefaults.standard.string(forKey: Keys.authToken) else {
            throw APIError.tokenNotFound
        }
        
        let url = "/users?token=" + token
        var dataDict = ["name": name]
        if !referralCode.isEmpty {
            dataDict["referral_code"] = referralCode
        }
        let jsonData = try JSONEncoder().encode(dataDict)
        
        
        try await request(with: url, method: .POST(jsonData)) { data, response in
            
            if response.statusCode == 400 {
                throw APIError.incorrectBody
            }
            
            guard response.statusCode == 201 else {
                throw APIError.wrongCode
            }
            
            do {
                let user = try JSONDecoder().decode(User.self, from: data)
                await MainActor.run {
                    self.user = user
                    if !referralCode.isEmpty {
                        self.user?.freshReferral = true
                    }
                }
            } catch {
                throw APIError.decodingError
            }
            
            return nil
        }
    }
    
    func refreshUser() async throws {
        guard let token = UserDefaults.standard.string(forKey: Keys.authToken) else {
            throw APIError.tokenNotFound
        }

        let url = "/users/me?token=\(token)"
        
        let userUpdate: User = try await request(with: url)
        await MainActor.run {
            self.user = userUpdate
        }
    }
    
    func uploadUserAvatar(image: UIImage) async throws {
        let url = "/users/me/photo"
        
        guard let imageString = image.toBase64() else {
            return
        }
        
        let jsonData = try JSONEncoder().encode(["image": imageString])
        
        
        try await request(with: url, method: .POST(jsonData)) { data, response in
            guard response.statusCode == 204 else {
                throw APIError.wrongCode
            }
        }
    }
    
    func update(name: String? = nil, 
                email: String? = nil,
                preferredLanguage: String? = nil,
                gender: User.Gender? = nil,
                dob: Date? = nil,
                country: Country? = nil) async throws -> User {
        struct UserUpdate: Encodable {
            let name: String?
            let email: String?
            let preferredLanguage: String?
            let gender: User.Gender?
            let dob: String?
            let country: Country?
            
            enum CodingKeys: String, CodingKey {
                case name
                case email
                case preferredLanguage = "preferred_language"
                case gender
                case dob = "date_of_birth"
                case country = "country_code"
            }
        }
        
        let url = "/users/me"
        
        var dobString: String? = nil
        
        if let dob = dob {
            dobString = Date.iso8601DateOnly.string(from: dob)
        }
        
        let userUpdate = UserUpdate(name: name,
                                    email: email,
                                    preferredLanguage: preferredLanguage,
                                    gender: gender,
                                    dob: dobString,
                                    country: country)
        
        let jsonData = try JSONEncoder().encode(userUpdate)

        return try await request(with: url, method: .PATCH(jsonData)) { data, response in
            guard response.statusCode == 200 else {
                throw APIError.wrongCode
            }
            
            do {
                let user = try JSONDecoder().decode(User.self, from: data)
                await MainActor.run {
                    self.user = user
                }
            } catch {
                throw APIError.decodingError
            }
            
            return nil
        }
    }
    
    func DEBUGdeleteAccount() async throws {
        let url = "/users/me"
        
        // WARNING: this will delete the account and all of its data permanently.
        // Make sure you're aware of that.
        try await request(with: url, method: .DELETE) { data, response in
            guard response.statusCode == 204 else {
                throw APIError.wrongCode
            }
        }
  
        // This is not necessary since the BE deletes the Firebase account.
//        try await Authentication().deleteUser()
    }
    
    func referralCode() async throws -> UserReferralCodeModel {
        let url = "/referral_code"
        
        return try await request(with: url, mockProtocol: nil)
    }
    
    func homeSections() async throws -> [HomeSectionModel] {
        return try await request(with: "/home_sections", mockProtocol: nil /*MockHomeSectionURLProtocol.self*/)
    }
    
    func packagesForMerchant(_ id: String) async throws -> [PackageModel] {
        let url = "/merchants/\(id.lowercased())/packages"
        
        return try await request(with: url, mockProtocol: nil /*MockProductsURLProtocol.self*/)
    }
    
    func storesForMerchant(_ id: String, location: CLLocationCoordinate2D? = nil) async throws -> [MerchantStoreModel] {
        var url = "/merchants/\(id.lowercased())/stores"
        
        if let location = location {
            url = url + "?lat=\(location.latitude)&lon=\(location.longitude)"
        }
        
        return try await request(with: url, mockProtocol: nil /*MockMerchantStoresURLProtocol.self*/)
    }
    
    func homeSection(for id: UUID) async throws -> HomeSectionModel {
        try await request(with: "/home_sections/\(id.uuidString.lowercased())")
    }
    
    func packageDetails(for id: UUID) async throws -> PackageModel {
        try await request(with: "/packages/\(id.uuidString.lowercased())")
    }
    
    func packageStores(for id: UUID) async throws -> [MerchantStoreModel] {
        try await request(with: "/packages/\(id.uuidString.lowercased())/stores")
    }
    
    func latestCart(promoCode: String? = nil) async throws -> CartModel {
        var url = "/carts/latest"
        if let promoCode = promoCode, !promoCode.trimmingCharacters(in: .whitespaces).isEmpty {
             url = url + "?promoCode=\(promoCode)"
        }
        return try await request(with: url) { data, response in
            guard response.statusCode == 200 else {
                throw APIError.wrongCode
            }
            
            return nil
        }
    }
    
    @discardableResult
    func addPackageToCart(_ id: UUID, quantity: Int = 1) async throws -> CartItem {
        struct NewCartItem: Encodable {
            let packageID: String
            let quantity: Int
            
            private enum CodingKeys: String, CodingKey {
                case packageID = "package_id"
                case quantity
            }
        }
        
        let url = "/carts/latest/items"
        let jsonData = try JSONEncoder().encode(NewCartItem(packageID: id.uuidString.lowercased(), quantity: quantity))
        
        return try await request(with: url, method: .POST(jsonData)) { data, response in
            guard response.statusCode == 200 else {
                throw APIError.wrongCode
            }
            
            do {
                let item = try JSONDecoder().decode(CartItem.self, from: data)
                return await MainActor.run {
                    return item
                }
            } catch {
                throw APIError.decodingError
            }
        }
    }
    
    func changeQuantityInCart(for id: UUID, quantity: Int) async throws {
        let url = "/carts/latest/items/\(id.uuidString.lowercased())"
        let jsonData = try JSONEncoder().encode(["quantity": quantity])
        
        try await request(with: url, method: .PUT(jsonData)) { [weak self] data, response in
            guard response.statusCode == 200 else {
                throw APIError.wrongCode
            }
            if response.statusCode == 404 {
                try await self?.addPackageToCart(id, quantity: quantity)
            }
        }
    }
    
    func deletePackageFromCart(_ id: UUID) async throws {
        let url = "/carts/latest/items/\(id.uuidString.lowercased())"
        
        try await request(with: url, method: .DELETE) { data, response in
            guard response.statusCode == 204 else {
                throw APIError.wrongCode
            }
        }
    }
    
    func createOrder(for cartid: UUID) async throws -> OrderModel {
        let url = "/orders"
        
        let jsonData = try JSONEncoder().encode(["cart_id": cartid.uuidString.lowercased()])
        
        return try await request(with: url, method: .POST(jsonData)) { data, response in
            guard response.statusCode == 201 else {
                throw APIError.wrongCode
            }
                
            return nil
        }
    }
    
    func orders(with filterDate: Date? = nil) async throws -> [OrderDetailModel] {
        var url = "/orders"
        if let filterDate = filterDate {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.timeZone = TimeZone(secondsFromGMT: 0)

            let isoDateString = isoFormatter.string(from: filterDate)
            url = url + "?createdAtGte=\(isoDateString)"
        }
        
        return try await request(with: url)
    }
    
    func redemptions(with filterDate: Date? = nil) async throws -> [RedemptionDetailModel] {
        var url = "/redemptions"
        if let filterDate = filterDate {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.timeZone = TimeZone(secondsFromGMT: 0)

            let isoDateString = isoFormatter.string(from: filterDate)
            url = url + "?createdAtGte=\(isoDateString)"
        }
        
        return try await request(with: url)
    }
    
    func walletMerchants() async throws -> [WalletMerchantModel] {
        let url = "/wallet/merchants"
        
        return try await request(with: url)
    }
    
    func walletMerchant(for id: UUID) async throws -> WalletMerchantModel {
        let url = "/wallet/merchants/\(id.uuidString.lowercased())"
        
        return try await request(with: url) { data, response in
            if response.statusCode == 404 {
                throw APIError.notFound
            }
            
            guard response.statusCode == 200 else {
                throw APIError.wrongCode
            }
            
            return nil
            
        }
    }
    
    func startRedemptions(for purchaseID: UUID, quantity: Int) async throws -> [RedemptionModel] {
        let url = "/redemptions"
        
        let redemption = RedemptionNew(purchaseId: purchaseID.uuidString.lowercased(), value: quantity)
        let jsonData = try JSONEncoder().encode(redemption)
        return try await request(with: url, method: .POST(jsonData)) { data, response in
            guard response.statusCode == 201 else {
        throw APIError.wrongCode
    }
            return nil
        }
    }
    
    func checkRedemptionStatus(for id: UUID) async throws -> RedemptionModel {
        let url = "/redemptions/\(id.uuidString.lowercased())"
        
        return try await request(with: url)
    }
    
    func children() async throws -> [ChildModel] {
        let url = "/children"
        
        return try await request(with: url)
    }
    
    func addChild(with name: String, dob: Date?) async throws -> ChildModel {
        let url = "/children"
        
        let jsonData = try JSONEncoder().encode(NewChild(name: name, dob: dob))
        
        return try await request(with: url, method: .POST(jsonData)) { data, response in
            guard response.statusCode == 201 else {
                throw APIError.wrongCode
            }
                
            return nil
        }
    }
    
    func deleteChild(with id: UUID) async throws {
        let url = "/children/\(id.uuidString.lowercased())"
        
        return try await request(with: url, method: .DELETE) { date, response in
            guard response.statusCode == 204 else {
                throw APIError.wrongCode
            }
        }
    }
    
    func updateChild(with id: UUID, name: String, dob: Date?) async throws -> ChildModel {
        let url = "/children/\(id.uuidString.lowercased())"
        
        let jsonData = try JSONEncoder().encode(NewChild(name: name, dob: dob))
        
        return try await request(with: url, method: .PUT(jsonData))
    }
    
    func startSession(for purchaseId: UUID, children: [UUID]) async throws -> SessionModel {
        let url = "/sessions"
        
        let jsonData = try JSONEncoder().encode(SessionNew(purchaseId: purchaseId.uuidString.lowercased(), 
                                                           childrenIds: children.map { $0.uuidString.lowercased() }))

        return try await request(with: url, method: .POST(jsonData))  { data, response in
            guard response.statusCode == 201 else {
                throw APIError.wrongCode
            }
                
            return nil
        }
    }
    
    func getSession(with id: UUID) async throws -> SessionModel {
        let url = "/sessions/\(id.uuidString.lowercased())"
        
        return try await request(with: url)
    }
    
    func getSessions() async throws -> [SessionModel] {
        let url = "/sessions"
        
        return try await request(with: url)
    }
    
    func savePushToken(_ token: String) async throws {
        let url = "/push_tokens"
        
        let jsonData = try JSONEncoder().encode(["token": token, "device_type": "ios"])
        
        try await request(with: url, method: .POST(jsonData))
    }
    
    func getAlerts() async throws -> [AlertModel] {
        let url = "/users/notifications"
        
        return try await request(with: url)
    }
    
    func markAsReadAlert(with id: UUID) async throws {
        let url = "/users/notifications"
        
        let jsonData = try JSONEncoder().encode(["user_notification_ids": [id.uuidString.lowercased()]])
        
        try await request(with: url, method: .PUT(jsonData)) { data, response in
            guard response.statusCode == 204 else {
                throw APIError.wrongCode
            }
        }
    }
    
    func markAsReadAllAlerts() async throws {
        let url = "/users/notifications"
        
        let jsonData = try JSONEncoder().encode(["is_read_all": true])
        
        try await request(with: url, method: .PUT(jsonData)) { data, response in
            guard response.statusCode == 204 else {
                throw APIError.wrongCode
            }
        }
    }
    
    func DEBUGchangeRedemptionStatus(for id: UUID, merchantId: UUID) async throws {
        let url = "/redemptions/\(id.uuidString.lowercased())/status"
        let update = RedemptionStatusUpdate(status: .success, merchantStoreId: merchantId.uuidString.lowercased())
        let jsonData = try JSONEncoder().encode(update)
        
        try await request(with: url, method: .PUT(jsonData))
    }
}

fileprivate struct NewChild: Encodable {
    let name: String
    @DecodableDayDate var dob: Date?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case dob = "date_of_birth"
    }
}

extension API {
    fileprivate enum Method {
        case GET
        case POST(Data)
        case PUT(Data)
        case PATCH(Data)
        case DELETE
    }
    
    fileprivate func performRequest<U: URLProtocol>(
        with urlString: String,
        method: Method = .GET,
        mockProtocol: U.Type? = nil,
        reauthenticate: Bool = true
    ) async throws -> (Data, HTTPURLResponse) {
        guard let token = UserDefaults.standard.string(forKey: Keys.authToken) else {
            throw APIError.tokenNotFound
        }

        guard let url = URL(string: Strings.baseURL + urlString) else {
            throw APIError.invalidURL
        }

        // Map `Method` enum to Alamofire's `HTTPMethod` and `parameters`
        let httpMethod: HTTPMethod
        var bodyData: Data?

        switch method {
        case .GET:
            httpMethod = .get
        case .POST(let jsonData):
            httpMethod = .post
            bodyData = jsonData
        case .PUT(let jsonData):
            httpMethod = .put
            bodyData = jsonData
        case .PATCH(let jsonData):
            httpMethod = .patch
            bodyData = jsonData
        case .DELETE:
            httpMethod = .delete
        }

        var headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        if bodyData != nil {
            headers.add(name: "Content-Type", value: "application/json")
        }

        // Configure Session with mockProtocol if needed
        let configuration = URLSessionConfiguration.default
        if let mock = mockProtocol {
            configuration.protocolClasses = [mock]
        }

        let session = Alamofire.Session(configuration: configuration)

        var urlRequest = URLRequest(url: url)
        urlRequest.method = httpMethod
        urlRequest.headers = headers
        if let body = bodyData {
            urlRequest.httpBody = body
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let dataRequest = session.upload(bodyData ?? Data(), with: urlRequest)
        
        // NOTE: use to debug the request object
        dataRequest.cURLDescription(calling: { (curl) in
            print(curl)
        })
        
        let response = await dataRequest
            .serializingData()
            .response

        guard let httpResponse = response.response else {
            throw APIError.invalidResponse
        }

        if reauthenticate && httpResponse.statusCode == 403 {
            print("reauthenticating....")
            do {
                let token = try await Authentication().reauthenticate()
                print("new token ====", token)
                UserDefaults.standard.set(token, forKey: Keys.authToken)
                return try await performRequest(with: urlString, method: method, mockProtocol: mockProtocol)
            } catch {
                print("reauthentication failed")
                await signOut()
                await MainActor.run {
                    sendToAuth = true
                }
            }
        }

        guard let responseData = response.data else {
            throw APIError.invalidResponse
        }

        return (responseData, httpResponse)
    }

    
    fileprivate func request<T: Decodable, U: URLProtocol>(
        with url: String,
        method: Method = .GET,
        reauthenticate: Bool = true,
        mockProtocol: U.Type? = nil,
        intercept: ((Data, HTTPURLResponse) async throws -> T?)? = { data, response in
            guard response.statusCode == 200 else {
        throw APIError.wrongCode
    }
            return nil
        }
    ) async throws -> T {
        let (data, response) = try await performRequest(with: url,
                                                        method: method,
                                                        mockProtocol: mockProtocol,
                                                        reauthenticate: reauthenticate)
        
        if let intercept = intercept, let decision = try await intercept(data, response) {
            return decision
        }
        
        return try decodeResponseData(data: data)
    }
    
    fileprivate func request<U: URLProtocol>(
        with url: String,
        method: Method = .GET,
        reauthenticate: Bool = true,
        mockProtocol: U.Type? = nil,
        intercept: ((Data, HTTPURLResponse) async throws -> Void?)? = { data, response in
            guard response.statusCode == 200 else {
        throw APIError.wrongCode
    }
            return nil
        }
    ) async throws {
        let (data, response) = try await performRequest(with: url,
                                                        method: method,
                                                        mockProtocol: mockProtocol,
                                                        reauthenticate: reauthenticate)
        
        if let intercept = intercept {
            _ = try await intercept(data, response)
        }
    }
    
    fileprivate func decodeResponseData<T: Decodable>(data: Data) throws -> T {
        do {
            let decodedResponse = try JSONDecoder().decode(T.self, from: data)
            return decodedResponse
        } catch {
            print("decode error ======", error)
            throw APIError.decodingError
        }
    }
}

enum APIError: Error {
    case wrongCode
    case incorrectBody
    case notFound
    case decodingError
    case invalidResponse
    case tokenNotFound
    case invalidURL
}

extension UIImage {
    func toBase64(compressionQuality: CGFloat = 1.0) -> String? {
        self.jpegData(compressionQuality: 1)?.base64EncodedString()
    }
}
