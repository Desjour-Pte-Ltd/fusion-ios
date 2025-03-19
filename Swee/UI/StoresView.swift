import SwiftUI

struct StoresView: View {
    var stores: [MerchantStore]
    @State private var selectedIndex: Int? = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Text("merchant_store_locations_title".i18n(with: stores.count.toString))
                .font(.custom("Poppins-SemiBold", size: 24))
                .foregroundStyle(Color.text.black100)
                .padding(.bottom, 24)
            ScrollView {
                ForEach(Array(stores.enumerated()), id: \.offset) { offset, store in
                    StoreRow(store: store, index: offset, isSelected: selectedIndex == offset) { index in
                        selectedIndex = index == selectedIndex ? nil : index
                    }
                }
                .padding(.horizontal, 5)
            }
            .frame(height: 300)
        }
        .animation(.default, value: selectedIndex)
    }
}

struct StoreRow: View {
    var store: MerchantStore
    var index: Int
    var isSelected: Bool
    var onTap: (_ index: Int) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("•  \(store.name)")
                        .font(.custom("Poppins-Bold", size: 16))
                        .foregroundStyle(Color.text.black80)
                        .padding(.bottom, 3)
                    Spacer()
                    Image("chevron-down")
                        .rotationEffect(.degrees(isSelected ? 180 : 0))
                        .foregroundStyle(Color.text.black100)
                }
                if isSelected {
                    VStack {
                        if let address = store.address {
                            HStack(alignment: .top) {
                                Image("location-filled")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 12, height: 12)
                                    .foregroundStyle(Color.text.black40)
                                    .padding(.top, 3)
                                Text(address)
                                    .font(.custom("Poppins-Regular", size: 12))
                                    .lineLimit(2)
                                    .foregroundStyle(Color.text.black40)
                                    .frame(maxHeight: .infinity)

                                Spacer()
                            }
                            .padding(.top, 12)
                        }
                        if let operatingHours = store.operatingHours {
                            HStack(alignment: .top) {
                                Image("time")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 12, height: 12)
                                    .foregroundStyle(Color.text.black40)
                                    .padding(.top, 3)
                                Text(operatingHours)
                                    .font(.custom("Poppins-Regular", size: 12))
                                    .foregroundStyle(Color.text.black40)
                                    .lineLimit(2)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            Spacer()
        }
        .onTapGesture {
            onTap(index)
        }
        .frame(maxWidth: .infinity)
    }
}
