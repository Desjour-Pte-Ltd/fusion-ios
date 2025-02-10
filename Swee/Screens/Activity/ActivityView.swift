import SwiftUI

enum ActivityTab {
    case Purchased
    case Redeemed
    
    var emptyDescription: String {
        switch self {
        case .Purchased:
            "You have not made any purchases yet"
        case .Redeemed:
            "You have not redeemed anything yet"
        }
    }
}

struct RedemptionsSection: Hashable {
    let date: Date
    let redemptions: [RedemptionDetail]
}

struct PurchasesSection: Hashable {
    let date: Date
    let purchases: [OrderDetail]
}

struct ActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabIsShown) private var tabIsShown
    @Environment(\.currentTab) private var currentTab
    @EnvironmentObject private var api: API
    
    @StateObject private var viewModel = ActivityViewModel()
    @State private var hideBottomSheet: Bool = true
    @State private var tab = ActivityTab.Purchased
    @State private var filter: DateFilter = .Anytime
    
    var noData: Bool {
        return viewModel.purchaseSections.isEmpty && 
        viewModel.redemptionSections.isEmpty &&
        viewModel.loadedData &&
        !viewModel.showError
    }
    
    func emptyUI(description: String) -> some View {
        VStack(spacing: 0) {
            Spacer()
            Image("empty-activity")
            Text("my_activity_empty_title")
                .font(.custom("Poppins-SemiBold", size: 24))
                .padding(.horizontal, 44)
                .foregroundStyle(Color.text.black100)
                .multilineTextAlignment(.center)
                .padding(.top, 24)
            Text(description.i18n)
                .font(.custom("Poppins-Regular", size: 14))
                .padding(.horizontal, 44)
                .foregroundStyle(Color.text.black60)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            Button {
                dismiss()
                currentTab.wrappedValue = .home
            } label: {
                HStack {
                    Text("my_activity_empty_cta")
                        .font(.custom("Roboto-Bold", size: 16))
                }
                .foregroundStyle(Color.background.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(LinearGradient(colors: Color.gradient.primaryDark, startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 22)
            .padding(.top, 60)
            Spacer()
            Spacer()
        }
    }
    
    var currentTabIsEmpty: Bool {
        switch tab {
        case .Purchased:
            viewModel.purchaseSections.isEmpty
        case .Redeemed:
            viewModel.redemptionSections.isEmpty
        }
    }
    
    var mainUI: some View {
        VStack(spacing: 0) {
            GeometryReader { metrics in
                ZStack {
                    HStack {
                        Capsule()
                            .frame(maxWidth: metrics.size.width / 2.2, maxHeight: 45, alignment: .leading)
                            .foregroundStyle(Color.primary.brand)
                    }
                    .frame(maxWidth: .infinity, alignment: tab == .Purchased ? .leading : .trailing)
                    .animation(.default, value: tab)
                    HStack {
                        Button {
                            tab = .Purchased
                        } label: {
                            Text("my_activity_tab_purchased")
                                .frame(maxWidth: .infinity)
                                .font(.custom(tab == .Purchased ? "Poppins-Bold" : "Poppins-Medium", size: 14))
                                .foregroundStyle(.white)
                        }
                        //                        .buttonStyle(EmptyStyle())
                        Spacer()
                        Button {
                            tab = .Redeemed
                        } label: {
                            Text("my_activity_tab_redeemed")
                                .frame(maxWidth: .infinity)
                                .font(.custom(tab == .Redeemed ? "Poppins-Bold" : "Poppins-Medium", size: 14))
                                .foregroundStyle(.white)
                        }
                        //                        .buttonStyle(EmptyStyle())
                    }
                    .animation(.default, value: tab)
                    
                }
                .background(Capsule()
                    .foregroundStyle(Color.primary.lighter))
                .padding()
            }
            .frame(height: 80)
            if !viewModel.loadedData {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        PurchaseRow.skeleton.equatable.view
                        PurchaseRow.skeleton.equatable.view
                        PurchaseRow.skeleton.equatable.view
                        PurchaseRow.skeleton.equatable.view
                    }
                    .padding(.top, 48)
                }
            } else if currentTabIsEmpty {
                emptyUI(description: tab.emptyDescription)
            } else {
               listsUI
            }
        }
    }
    
    var purchaseList: some View {
        ForEach(Array(viewModel.purchaseSections.enumerated()), id: \.offset) { sectionIndex, section in
            Section {
                ForEach(Array(section.items.enumerated()), id: \.offset) { index, purchase in
                    PurchaseRow(purchase: purchase, hideDivider: index == 0)
                }
                
            } header: {
                ActivitySectionHeader(date: section.date)
            }
            
        }
        .listRowSeparator(.hidden, edges: .all)
    }
    
    var redemptionList: some View {
        ForEach(Array(viewModel.redemptionSections.enumerated()), id: \.offset) { sectionIndex, section in
            Section {
                ForEach(Array(section.items.enumerated()), id: \.offset) { index, redemption in
                    RedemptionRow(redemption: redemption, hideDivider: index == 0)
                }
            } header: {
                ActivitySectionHeader(date: section.date)
            }
            
        }
        .listRowSeparator(.hidden, edges: .all)
    }
    
    var listsUI: some View {
        List {
            if tab == .Purchased {
               purchaseList
            } else {
               redemptionList
            }
            HStack {
                Rectangle()
                    .fill(Color.text.black10)
                    .frame(height: 1)
                Text("my_activity_tab_end_divider")
                    .font(.custom("Poppins-Medium", size: 10))
                    .foregroundStyle(Color.text.black40)
                Rectangle()
                    .fill(Color.text.black10)
                    .frame(height: 1)
            }
            .padding(.top, 20)
            .padding([.leading, .trailing], -10)
            .listRowSeparator(.hidden, edges: .all)
        }
        .listStyle(.inset)
    }
    
    var body: some View {
        ZStack {
            if viewModel.showError {
                StateView.error {
                    try? await viewModel.fetch(with: filter)
                }
            } else if !noData {
              mainUI
            } else {
                emptyUI(description: "my_activity_empty_description")
            }
        }
        .onAppear(perform: {
            viewModel.api = api
            Task {
                try? await viewModel.fetch(with: filter)
            }
            tabIsShown.wrappedValue = false
        })
        .customNavigationTitle("my_activity_title")
        .customNavTrailingItem {
            if noData {
                CartButton()
            } else {
                Button {
                    hideBottomSheet = false
                } label: {
                    ZStack {
                        Image("filter")
                        if filter != .Anytime {
                            VStack(alignment: .trailing, spacing: 0) {
                                HStack(spacing: 0) {
                                    Spacer()
                                    Circle()
                                        .foregroundStyle(Color(hex: "#DA1E28"))
                                        .frame(width: 12, height: 12)
                                        .padding(.trailing, 2)
                                        .padding(.top, 0)
                                }
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .animation(.default, value: filter)
                    .frame(width: 40, height: 24)
                    //                        .background(.green)
                }
                .buttonStyle(EmptyStyle())
            }
        }
        .customBottomSheet(hidden: $hideBottomSheet) {
            FiltersView(dateFilter: filter) { filter in
                self.filter = filter
                Task {
                    try? await viewModel.fetch(with: filter)
                }
                hideBottomSheet = true
            }
        }
    }
}

enum DateFilter: Int, CaseIterable {
    case Anytime
    case ThisWeek
    case Past30Days
    case Past90Days
    case Past6Months
    case PastYear
    
    func toString() -> String {
        switch self {
        case .Anytime:
            return "my_activity_filter_anytime"
        case .ThisWeek:
            return "my_activity_filter_this_week"
        case .Past30Days:
            return "my_activity_filter_past_30_days"
        case .Past90Days:
            return "my_activity_filter_past_90_days"
        case .Past6Months:
            return "my_activity_filter_past_6_months"
        case .PastYear:
            return "my_activity_filter_past_year"
        }
    }
    
    var date: Date? {
        switch self {
        case .Anytime:
            return nil
        case .ThisWeek:
            return Calendar.current.date(byAdding: .day, value: -7, to: .now)
        case .Past30Days:
            return Calendar.current.date(byAdding: .month, value: -1, to: .now)
        case .Past90Days:
            return Calendar.current.date(byAdding: .month, value: -3, to: .now)
        case .Past6Months:
            return Calendar.current.date(byAdding: .month, value: -6, to: .now)
        case .PastYear:
            return Calendar.current.date(byAdding: .year, value: -1, to: .now)
        }
    }
}

struct FiltersView: View {
//    @State private var vendorFilters: Set<Vendors> = [.Zoomoov, .Jollyfield]
    @State var dateFilter: DateFilter = .Anytime
    var onFiltersChange: (DateFilter) -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text("my_activity_filter_title")
                    .font(.custom("Poppins-SemiBold", size: 24))
                Spacer()
                Button {
                    onFiltersChange(dateFilter)
                } label: {
                    Text("cta_apply")
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundStyle(Color.primary.brand)
                }
            }
            .padding([.leading, .trailing], 8)
            .padding(.top, -16)
            Rectangle()
                .fill(Color.text.black20)
                .frame(height: 1)
                .padding(.bottom)
                .padding([.leading, .trailing], -20)
            VStack(spacing: 8) {
                Text("my_activity_filter_by_date")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 2) {
                    ForEach(DateFilter.allCases, id: \.self) { filter in
                        FilterRow(title: filter.toString(),
                                  selected: dateFilter == filter) {
                            dateFilter = filter
                        }
                    }
                }
            }
        }
    }
}

struct FilterRow: View {
    var title: String
    var selected: Bool
    var onTapClosure: () -> Void
    
    var body: some View {
        Button {
            onTapClosure()
        } label: {
            HStack {
                Text(title.i18n)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundStyle(selected ? Color.primary.brand : Color.text.black60)
                Spacer()
                Image("checkmark")
                    .hidden(!selected)
                    .foregroundStyle(Color.primary.brand)
            }
        }
        .padding([.trailing, .leading], 12)
        .padding([.top, .bottom], 10)
        .background(selected ? Color.primary.lighter.opacity(0.15) : .white)
    }
    
}

struct ActivitySectionHeader: View {
    @State var date: Date
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.text.black10)
                .frame(height: 1)
            Text("\(date.formatted(date: .abbreviated, time: .omitted))")
                .font(.custom("Poppins-Medium", size: 12))
                .foregroundStyle(Color.text.black40)
            Rectangle()
                .fill(Color.text.black10)
                .frame(height: 1)
        }
        .padding([.leading, .trailing], -10)
    }
}

struct PurchaseRow: View {
    @State var purchase: OrderDetail
    @State var hideDivider: Bool = false
    
    var body: some View {
        VStack {
            if !hideDivider {
                Divider()
                    .background(Color.text.black10)
            }
            HStack(spacing: 0) {
                Circle()
                    .foregroundStyle(LinearGradient(
                        colors: purchase.bgColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(String(purchase.merchantName.first ?? "N"))
                            .foregroundStyle(.white)
                            .font(.custom("Poppins-Bold", size: 16))
                    }
                    .padding(.trailing, 16)
                VStack(alignment: .leading, spacing: 4) {
                    Text(purchase.merchantName)
                        .font(.custom("Poppins-SemiBold", size: 14))
                    Text("my_activity_number_of_items".i18n(with: purchase.quantity.toString))
                        .font(.custom("Poppins-SemiBold", size: 12))
                    Text("\(purchase.type.toString.i18n) | \(purchase.createdAt.formatted(date: .omitted, time: .shortened))")
                        .font(.custom("Poppins-SemiBold", size: 10))
                        .foregroundStyle(Color.text.black40)
                }
                Spacer()
                Text("\(purchase.currencyCode) \(purchase.totalPriceCents / 100)")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundStyle(Color.primary.brand)
            }
        }
    }
}

extension PurchaseRow: Skeletonable {
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

extension OrderType {
    var toString: String {
        switch self {
        case .online:
            return "my_activity_mode_of_purchase_online"
        case .otc:
            return "my_activity_mode_of_purchase_counter"
        }
    }
}

struct RedemptionRow: View {
    @State var redemption: RedemptionDetail
    @State var hideDivider: Bool = false
    private var storeAndTime: String {
        return "\(redemption.storeName) | \(redemption.createdAt.formatted(date: .omitted, time: .shortened))"
    }
    
    var body: some View {
        VStack {
            if !hideDivider {
                Divider()
                    .background(Color.text.black10)
            }
            HStack(spacing: 0) {
                Circle()
                    .foregroundStyle(LinearGradient(
                        colors: redemption.bgColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(String(redemption.merchantName.first ?? "N"))
                            .foregroundStyle(.white)
                            .font(.custom("Poppins-Bold", size: 16))
                    }
                    .padding(.trailing, 16)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(redemption.merchantName) \(redemption.productName.singularName)")
                        .font(.custom("Poppins-SemiBold", size: 14))
                    Text(storeAndTime)
                        .font(.custom("Poppins-SemiBold", size: 10))
                        .foregroundStyle(Color.text.black40)
                }
                Spacer()
                Text("- \(redemption.value) \(redemption.productName.singularName)")
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundStyle(Color.secondary.brand)
            }
            .padding(.top, 10)
        }
    }
}

#Preview {
    CustomNavView {
        ActivityView()
    }
}
