import SwiftUI

struct JollyfieldRedemptionView: View {
    @Environment(\.tabIsShown) private var tabIsShown
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var api: API
    @EnvironmentObject private var activeSession: ActiveSession
    
    @State var merchant: WalletMerchant
    @StateObject private var viewModel = JollyfieldRedemptionViewModel()
    @State var hidden = true
    
    var emptyUI: some View {
        VStack {
            Image("family")
            Text("redemption_add_child_empty_state_title")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundStyle(Color.text.black80)
            Text("redemption_add_child_empty_state_description")
                .font(.custom("Poppins-Medium", size: 14))
                .padding(.horizontal, 28)
                .foregroundStyle(Color.text.black60)
                .multilineTextAlignment(.center)
            CustomNavLink(destination: AddChildView(children: viewModel.children) { children in
                viewModel.children = children
            }) {
                HStack {
                    Text("redemption_add_child_empty_state_cta")
                        .font(.custom("Roboto-Bold", size: 16))
                    Image("plus")
                }
                .foregroundStyle(LinearGradient(colors: Color.gradient.primary, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 24)
            .padding(.horizontal, 28)
            .padding(.bottom, 60)
        }
    }
    
    var dottedOutline: some View {
        
        if viewModel.children.isEmpty || sessionOngoing {
            return RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                .foregroundStyle(Color.black.opacity(0.3))
                .padding(.top, 50)
                .padding(.bottom, 0)
                .padding(.horizontal, -16)
        }
        
        if viewModel.selectedChildren.isEmpty {
            return RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                .foregroundStyle(Color.clear)
                .padding(.top, 50)
                .padding(.bottom, 0)
                .padding(.horizontal, -16)
        }
        
        let index = viewModel.indexOfLastSelectedChild
        let multiplier = viewModel.children.count - 1 - index // since we're pushing the lower side of the dotted line, I need to know how many cards up I need to push
        let cardHeight: CGFloat = 120
        let vPaddingBetweenCards: CGFloat = 16
        let heightOfDisclaimer: CGFloat = 24
        
        return RoundedRectangle(cornerRadius: 8)
            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
            .foregroundStyle(Color.primary.brand)
            .padding(.top, 50)
            .padding(.bottom, cardHeight * CGFloat(multiplier) + cardHeight / 2 + (vPaddingBetweenCards * CGFloat(multiplier)) + heightOfDisclaimer)
            .padding(.horizontal, -16)
    }
    
    var sessionOngoing: Bool {
        viewModel.session?.status == .inProgress
    }
    
    var loadingUI: some View {
        VStack {
            Color.white
                .skeleton(with: true, shape: .rounded(.radius(12, style: .circular)))
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 42)
            Color.white
                .skeleton(with: true, shape: .rounded(.radius(12, style: .circular)))
                .frame(height: 120)
                .frame(maxWidth: .infinity)
            Color.white
                .skeleton(with: true, shape: .rounded(.radius(12, style: .circular)))
                .frame(height: 120)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .padding(.horizontal, 16)
    }
    
    var mainUI: some View {
        VStack {
            VStack {
                VStack {
                    Text("\(viewModel.availableTime.toString()) Hr")
                        .font(.custom("Roboto-Bold", size: 32))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 2, x: 1, y: 2)
                    Text("purchased_total_time")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundStyle(.white.opacity(0.6))
                        .shadow(color: .black.opacity(0.25), radius: 2, x: 1, y: 2)
                }
                .frame(maxWidth: viewModel.children.isEmpty ? nil : .infinity, maxHeight: 100)
                .padding(.horizontal, 40)
                .padding(.vertical, 21)
                .background(RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                    .foregroundStyle(Color.black.opacity(0.3))
                )
                .background(RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(LinearGradient(colors: Color.gradient.primary, startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                HStack(spacing: 0) {
                    if let validUntilDate = viewModel.validUntilDate {
                        Text("redemption_validity")
                            .foregroundStyle(Color.text.black60)
                            .font(.custom("Poppins-Medium", size: 12))
                        Text(" \(validUntilDate.formatted(date: .abbreviated, time: .omitted))")
                            .foregroundStyle(Color.text.black100)
                            .font(.custom("Poppins-Medium", size: 12))
                    }
                }
                .padding(.bottom, 16)

                if viewModel.children.isEmpty {
                    emptyUI
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.children.indices, id: \.self) { index in
                            let child = viewModel.children[index]
                            let isSelected = viewModel.selectedChildren.contains(child)
                            ChildCard(child: child,
                                      sessionOngoing: sessionOngoing,
                                      alottedTime: viewModel.alottedTime,
                                      isSelected: isSelected) { child in
                                if sessionOngoing {
                                    return
                                }
                                if isSelected {
                                    viewModel.selectedChildren.remove(child)
                                } else {
                                    viewModel.selectedChildren.insert(child)
                                }
                            }
                        }
                        Text("redemption_hint")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundStyle(Color.text.black60)
                            .hidden(!viewModel.selectedChildren.isEmpty)
                    }
                }
            }
            .background(dottedOutline)
            .animation(.snappy, value: viewModel.selectedChildren)
            .padding(16)
        }
        .padding(.horizontal, 16)
    }
    
    var body: some View {
        ZStack {
            if viewModel.showError {
                StateView.error {
                    try? await viewModel.fetch()
                }
            } else {
                VStack(spacing: 0) {
                    ScrollView {
                        if !viewModel.loadedData {
                            loadingUI
                        } else {
                            mainUI
                        }
                    }
                    VStack(spacing: 0) {
                        if sessionOngoing {
                            Button {
                                hidden = false
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("redemption_end_timer_cta")
                                        .font(.custom("Roboto-Bold", size: 16))
                                    Spacer()
                                }
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .clipShape(Capsule())
                                .contentShape(Capsule())
                            }
                            .buttonStyle(OutlineButton(strokeColor: .red))
                        } else {
                            AsyncButton(progressWidth: .infinity) {
                                if viewModel.selectedChildren.isEmpty { return }
                                
                                do {
                                    try await viewModel.startSession(for: Array(viewModel.selectedChildren))
                                } catch {
                                    return
                                }
                                
                                hidden = false
                            } label: {
                                HStack {
                                    Text("redemption_start_timer_cta")
                                        .font(.custom("Roboto-Bold", size: 16))
                                    Image("timer")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryButton())
                        }
                    }
                    .padding([.leading, .trailing, .top], 16)
                    .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor(Color.text.black10), alignment: .top)
                }
                .background(Color.background.white)
            }
        }
        .onAppear(perform: {
            viewModel.api = api
            if merchant == WalletMerchant.empty,
               let merchant = activeSession.merchant {
                viewModel.merchant = merchant
            } else {
                viewModel.merchant = merchant
            }
            viewModel.activeSession = activeSession
            activeSession.changeFrequency(to: 1)
            viewModel.dismiss = dismiss
            Task {
                try? await viewModel.fetch()
            }
            tabIsShown.wrappedValue = false
        })
        .onDisappear(perform: {
            activeSession.changeFrequency(to: 5)
        })
        .customBottomSheet(hidden: $hidden) {
            JollyfieldBottomSheet(session: viewModel.session) {
                Task {
                    try? await viewModel.fetch()
                }
                hidden = true
            }
        }
        .customNavigationTitle("Jollyfield")
        .customNavTrailingItem {
            if viewModel.children.isEmpty {
                Text("")
            } else if sessionOngoing {
                Button {
                    openURL(URL(string: Strings.helpLink)!)
                } label: {
                    HStack(spacing: 4) {
                        Text("cta_help")
                            .font(.custom("Poppins-Medium", size: 16))
                        Image(systemName: "questionmark.circle")
                            .font(.callout.weight(.medium))
                    }
                    .foregroundStyle(Color.primary.brand)
                }
            } else {
                CustomNavLink(destination: AddChildView(children: viewModel.children) { children in
                    viewModel.children = children
                }) {
                    Text("redemption_add_child_empty_state_cta")
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundStyle(Color.primary.brand)
                }
            }
        }
    }
}

#Preview {
    CustomNavView {
        JollyfieldRedemptionView(merchant: .empty)
    }
}

struct JollyfieldBottomSheet: View {
    enum RedemptionStep: Equatable {
        case qrStart
        case sessionStarted
        case qrEnd
        case sessionEnded
    }
    
    @EnvironmentObject var api: API
    @State var step: RedemptionStep = .qrStart
    @State var timer: DispatchSourceTimer?
    var session: Session?
    var onComplete: () -> Void

    func poll(for session: Session, status: SessionStatus, goTo: RedemptionStep) {
        self.timer?.cancel()
        let queue = DispatchQueue.global(qos: .background)
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .seconds(2), leeway: .seconds(1))
        timer.setEventHandler(handler: {
            print("polling session \(status == .inProgress ? "start" : "end") for session \(session.id.uuidString.lowercased()).....")
            Task {
                if try await checkIfSession(is: status, goTo: goTo) {
                    print("polling succeeded for \(session.id.uuidString.lowercased())")
                    self.timer?.cancel()
                    self.timer = nil
                } else {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
        })
        timer.resume()
        
        self.timer = timer
    }
    
    @discardableResult
    func checkIfSession(is status: SessionStatus, goTo step: RedemptionStep) async throws -> Bool {
        guard let session = session else {
            return false
        }
        let currentStatus = try await api.getSession(with: session.id).toLocal().status
        if currentStatus == status {
            await MainActor.run {
                self.step = step
            }
            return true
        }
        
        return false
    }
    
    var body: some View {
        VStack {
            if session != nil {
                switch step {
                case .qrStart:
                    RedemptionScanView(model: .init(header: "redemption_scan_to_start_session", title: "redemption_scan_qr_to_start_session_title", qr: session?.qrCodeImage, description: "redemption_scan_qr_to_start_session_description", actionTitle: "cta_refresh", showCurrentTime: true)) {
                        try await checkIfSession(is: .inProgress, goTo: .sessionStarted)
                    }
                case .sessionStarted:
                    RedemptionCompletedView(model: .init(header: "", title: "redemption_scan_qr_to_start_session_success_message", description: "", actionTitle: "cta_okay")) {
                        onComplete()
                    }
                case .qrEnd:
                    RedemptionScanView(model: .init(header: "redemption_scan_to_end_session", title: "redemption_scan_qr_to_end_session_title", qr: session?.qrCodeImage, description: "redemption_scan_qr_to_end_session_description", actionTitle: "cta_refresh", showCurrentTime: true)) {
                        try await checkIfSession(is: .completed, goTo: .sessionEnded)
                    }
                case .sessionEnded:
                    let remainingTime = session?.remainingTime ?? ""
                    RedemptionCompletedView(model: .init(header: "", title: "redemption_scan_qr_to_end_session_success_message", description: "redemption_scan_qr_to_end_session_success_description".i18n(with: remainingTime), actionTitle: "cta_okay")) {
                        onComplete()
                        step = .qrStart
                    }
                }
            } else {
                // @todo show error screen
            }
           
        }
        .animation(.snappy, value: step)
        .onAppear {
            guard let session = session else {
                return
            }
            if session.status == .notStarted {
                step = .qrStart
                poll(for: session, status: .inProgress, goTo: .sessionStarted)
            } else if session.status == .inProgress {
                step = .qrEnd
                poll(for: session, status: .completed, goTo: .sessionEnded)
            }
        }
        .onDisappear {
            timer?.cancel()
            timer = nil
        }
    }
}
