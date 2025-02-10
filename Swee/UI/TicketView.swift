import SwiftUI

struct TicketView: View {
    var ticket: Ticket
    
    private let ticketHeight: CGFloat = 126
    private let notchSize: CGFloat = 15
    var notchOffset: CGFloat {
        return 44 + notchSize / 2
    }
    var body: some View {
        ZStack {
            TicketShape()
                .fill(LinearGradient(gradient: Gradient(colors: ticket.colors), startPoint: .topLeading, endPoint: .bottomTrailing).opacity(0.2))
                .frame(maxWidth: .infinity, maxHeight: ticketHeight)
                .padding([.top], 18)
                .padding([.leading], 8)
            TicketShape()
                .fill(LinearGradient(gradient: Gradient(colors: ticket.colors), startPoint: .topLeading, endPoint: .bottomTrailing).opacity(0.45))
                .frame(maxWidth: .infinity, maxHeight: ticketHeight)
                .padding([.top], 10)
                .padding([.leading, .trailing], 4)
            TicketShape()
                .fill(LinearGradient(gradient: Gradient(colors: ticket.colors), startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(maxWidth: .infinity, maxHeight: ticketHeight)
                .padding(.trailing, 8)
                .overlay(
                    DottedLine()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [8]))
                        .frame(width: 1, height: ticketHeight - notchSize * 2 - 10)
                        .foregroundColor(.black.opacity(0.25))
                        .position(CGPoint(x: notchOffset, y: ticketHeight / 2))
                )
                .overlay(
                    Text(ticket.merchant.uppercased())
                        .padding(.horizontal, 10)
                        .frame(width: 126)
                        .font(.custom("Poppins-SemiBold", size: 14))
                        .foregroundStyle(.black.opacity(0.3))
                        .transformEffect(.init(rotationAngle: -1.5708))
                        .position(CGPoint(x: 75, y: 136))
                        .lineLimit(1)
                )
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: -10) {
                    VStack {
                        Text("\(ticket.quantity)")
                            .font(.custom("Poppins-SemiBold", size: 66))
                        +
                        Text(" " + ticket.type)
                            .font(.custom("Poppins-Bold", size: 24))
                    }
                    .addInnerShadow()
                    VStack {
                        Text("purchased_valid_until")
                            .font(.custom("Poppins-SemiBold", size: 12))
                            .foregroundColor(.white.opacity(0.5)) +
                        Text("  \(ticket.expirationDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.custom("Poppins-SemiBold", size: 12))
                            .foregroundColor(.white.opacity(0.86))
                    }
                    .padding(.leading, 8)
                }
                Spacer()
                Image("double-chevron")
                    .foregroundStyle(.white)
            }
            .padding(.leading, 90)
            .padding([.trailing, .bottom], 24)
        }
        .frame(height: ticketHeight + 20)
    }
    
}

struct DottedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        return path
    }
}

struct TicketShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let cornerRadius: CGFloat = 12
        let notchSize: CGFloat = 15
        let notchOffset: CGFloat = 44 + notchSize / 2
        
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        
        // Add the top-left notch
        path.move(to: CGPoint(x: rect.minX + notchOffset, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.minX + notchOffset, y: rect.minY),
                    radius: notchSize,
                    startAngle: .degrees(180),
                    endAngle: .degrees(0),
                    clockwise: true)
        
        // Add the bottom-left notch
        path.move(to: CGPoint(x: rect.minX + notchOffset, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + notchOffset, y: rect.maxY),
                    radius: notchSize,
                    startAngle: .degrees(0),
                    endAngle: .degrees(180),
                    clockwise: true)
        
        path.move(to: CGPoint(x: rect.minX + notchOffset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        
        return path
    }
}

extension TicketView: Skeletonable {
    static var skeleton: any View {
        Color.white
            .skeleton(with: true, shape: .rounded(.radius(12, style: .circular)))
                .frame(height: 135)
    }
}
