import SwiftUI

struct ZoomoovBottomSheet: View {
    @EnvironmentObject var api: API
    @State var step: ZoomoovRedemptionSteps = .setup
    @Binding var model: ZoomoovRedemptionModel
    private var successfulScans: Int {
        redemptions.filter { $0.status == .success }.count
    }
    @State private var redemptions: [Redemption] = []
    @State var timer: DispatchSourceTimer?
    @State private var currentRedemption: Redemption?
    
    var onComplete: () -> Void
    
    func poll(for redemption: Redemption) {
        self.timer?.cancel()
        currentRedemption = redemption
        let queue = DispatchQueue.global(qos: .background)
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .seconds(2), leeway: .seconds(1))
        timer.setEventHandler(handler: {
            print("polling for \(redemption.id.uuidString.lowercased()).....")
            Task {
                let status = try await checkRedemptionStatus(for: redemption.id)
                guard status != .success else {
                    print("poll successful for \(redemption.id.uuidString.lowercased())")
                    if let currentRedemption = currentRedemption, currentRedemption.id == redemption.id {
                        self.timer?.cancel()
                        self.timer = nil
                    }
                    return
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        })
        timer.resume()
        
        print("reset timer")
        self.timer = timer
    }
    
    func checkRedemptionStatus(for id: UUID) async throws -> RedemptionStatus {
        let redemptionUpdate = try await api.checkRedemptionStatus(for: id)
        await MainActor.run {
            if redemptionUpdate.status == .success, let index = redemptions.firstIndex(where: { $0.id == id }) {
                redemptions[index] = redemptionUpdate.toLocal()
                goToNextRedemption()
            }
        }
        
        return redemptionUpdate.status
    }
    
    func goToNextRedemption() {
        if let nextRedemption = redemptions.first(where: { $0.status != .success }) {
            step = .redemptionQueue(nextRedemption)
            poll(for: nextRedemption)
        } else {
            step = .completed
        }
    }
    
    var body: some View {
        VStack {
            switch step {
            case .setup:
                ZoomoovRedemptionSetupView(model: $model) {
                    do {
                        let redemptions = try await api.startRedemptions(for: model.purchaseId,
                                                                         quantity: model.qtyToRedeem)
                        .map { $0.toLocal() }
                        await MainActor.run {
                            self.redemptions = redemptions
                            guard !redemptions.isEmpty else {
                                step = .error
                                return
                            }
                            goToNextRedemption()
                        }
                    } catch {
                        print("error =======", error)
                        step = .error
                    }
                }
            case .redemptionQueue(let redemption):
                RedemptionScanView(model: .init(header: "\(model.type.capitalized) \(successfulScans + 1)/\(model.qtyToRedeem)",
                                                title: "redemption_scan_qr_to_redeem_coupon_title",
                                                qr: redemption.qrCodeImage,
                                                description: "redemption_scan_qr_to_redeem_coupon_description",
                                                actionTitle: "redemption_scan_qr_cta",
                                                showCurrentTime: true),
                                   tint: Color.secondary.brand) {
                    do {
                        let status = try await checkRedemptionStatus(for: redemption.id)
                        guard status != .success else { return }
                        self.timer?.cancel()
                        self.timer = nil
                    } catch {
                        // fail silently
                    }
                }
            case .completed:
                RedemptionCompletedView(model: .init(header: "\(model.type.capitalized) \(successfulScans)/\(model.qtyToRedeem)",
                                                     title: "redemption_scan_qr_to_redeem_coupon_success_message".i18n(with: model.qtyToRedeem.toString, model.type),
                                                     description: "",
                                                     actionTitle: "cta_done"),
                                        tint: Color.secondary.brand) {
                    onComplete()
                    step = .setup
                }
            case .error:
                RedemptionErrorView(model: .init(header: "Redemption failed", title: "Failed to initiate redemption", qr: nil, description: "", actionTitle: "Retry")) {
                    step = .setup
                }
            }
        }
        .animation(.default, value: step)
        .onDisappear {
            timer?.cancel()
            timer = nil
        }
    }
}
