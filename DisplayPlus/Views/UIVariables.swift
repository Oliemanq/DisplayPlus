//
//  TestButton.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/31/25.
//
import SwiftUI

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

struct FloatingButtonStyle: ViewModifier {
    var primaryColor: Color
    var secondaryColor: Color
    var namespace: Namespace.ID
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        let darkMode: Bool = (colorScheme == .dark)
        
        if #available(iOS 26, *){
            content
                .frame(width: 65, height: 55)
                .glassEffect(.regular.tint(darkMode ? primaryColor : secondaryColor).interactive(true)) //, in: Rectangle()
                .glassEffectID("floatingButton", in: namespace)
                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                .fontWeight(.semibold)
        }else{
            content
                .font(.system(size: 22))
                .fontWeight(.semibold)
                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                .padding(7)
                .contentShape(.rect(cornerRadius: 12))
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
        }
    }
}
extension Image {
    func floatingButtonStyle(prim: Color, sec: Color, namespace: Namespace.ID) -> some View {
        modifier(FloatingButtonStyle(primaryColor: prim, secondaryColor: sec, namespace: namespace))
    }
}
struct FloatingTextStyle: ViewModifier {
    var primaryColor: Color
    var secondaryColor: Color
    var text: String
    var namespace: Namespace.ID
    var scale: CGFloat?
    @Environment(\.colorScheme) private var colorScheme

    
    func body(content: Content) -> some View {
        let darkMode: Bool = (colorScheme == .dark)
        let textCount: CGFloat = CGFloat(text.count)
        
        if #available(iOS 26, *){
            content
                .frame (width: (120+(textCount*1.25))*(scale ?? 1), height: 55*(scale ?? 1))
                .glassEffect(.regular.tint(darkMode ? primaryColor : secondaryColor).interactive(true)) //, in: Rectangle()
                .glassEffectID("floatingButton", in: namespace)
                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                .font(.system(size: 16*(scale ?? 1)))
                .fontWeight(.semibold)
        }else{
            content
                .font(.system(size: 12))
                .fontWeight(.semibold)
                .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                .padding(10)
                .contentShape(.rect(cornerRadius: 8))
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 8))
        }
    }
}
extension Text {
    func floatingTextStyle(prim: Color, sec: Color, text: String, namespace: Namespace.ID, scale: CGFloat?) -> some View {
        modifier(FloatingTextStyle(primaryColor: prim, secondaryColor: sec, text: text, namespace: namespace, scale: scale))
    }
}

struct FloatingButtonItem: Identifiable {
    private(set) var id: UUID = .init()
    var iconSystemName: String
    var extraText: String?
    var action: () -> Void
}

struct FloatingButtons: View {
    let items: [FloatingButtonItem]
    let standardOffset: CGFloat = 65
    
    @Environment(\.colorScheme) private var colorScheme
        
    @State var isExpanded: Bool = false
    @State private var isPressed: Bool = false
    @EnvironmentObject var theme: ThemeColors
    @Namespace private var namespace
    
    var body: some View {
        let primaryColor = theme.primaryColor
        let secondaryColor  = theme.secondaryColor
        
        ZStack {
            //Custon popup menu and buttons
            if #available(iOS 26, *){
                //Background when button pressed
                if isExpanded {
                    VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
                        .onTapGesture {
                            withAnimation{
                                isExpanded = false
                            }
                        }
                        .ignoresSafeArea()
                        .opacity(0.9)
                }
                
                //Left button
                GeometryReader { geometry in
                    GlassEffectContainer(spacing: 10){
                        ZStack{
                            if isExpanded{
                                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                                    HStack(spacing: 0){
                                        Image(systemName: item.iconSystemName)
                                            .floatingButtonStyle(prim: primaryColor, sec: secondaryColor, namespace: namespace)
                                            .font(.system(size: 28))
                                        
                                        Text(item.extraText ?? "")
                                            .floatingTextStyle(prim: primaryColor, sec: secondaryColor, text: item.extraText ?? "", namespace: namespace, scale: 1)
                                            .offset(x: -5)
                                    }
                                    .onTapGesture {
                                        withAnimation{
                                            item.action()
                                            isExpanded.toggle()
                                        }
                                    }
                                    .offset(y: -CGFloat(index+1) * standardOffset)
                                }.offset(x: -10)
                            }
                            Image(systemName: !isExpanded ? "folder.badge.plus" : "folder.fill.badge.plus")
                                .floatingButtonStyle(prim: primaryColor, sec: secondaryColor, namespace: namespace)
                                .font(.system(size: !isPressed ? 28 : 34))
                                .onTapGesture {
                                    withAnimation {
                                        isExpanded.toggle()
                                    }
                                    
                                }
                                .offset(x: !isExpanded ? 0 : -standardOffset) //Fix random offset when expanded
                        }
                    }.position(x: standardOffset-10, y: geometry.frame(in: .global).maxY - 75)
                        .offset(x: !isExpanded ? 0 : standardOffset)
                }
                
                
                
            }else{
                NavigationStack {
                    GeometryReader { geometry in
                        if isExpanded {
                            VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                                .onTapGesture {
                                    withAnimation{
                                        isExpanded = false
                                    }
                                }
                                .ignoresSafeArea()
                                .frame(width: 10000, height: 10000)
                        }
                        
                        ZStack{
                            if isExpanded{
                                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                                    
                                    HStack(){
                                        Image(systemName: item.iconSystemName)
                                            .floatingButtonStyle(prim: primaryColor, sec: secondaryColor, namespace: namespace)
                                            .onTapGesture {
                                                item.action()
                                                withAnimation{
                                                    isExpanded.toggle()
                                                }
                                            }
                                        Text(item.extraText ?? "")
                                            .floatingTextStyle(prim: primaryColor, sec: secondaryColor, text: item.extraText ?? "", namespace: namespace, scale: 1)
                                        Spacer()
                                    }
                                    .opacity(isExpanded ? 1 : 0)
                                    .offset(x: isExpanded ? -15 : 10, y: isExpanded ? -standardOffset*CGFloat(index+1) : 0)
                                    .animation(.easeInOut(duration: 0.2).delay(0.03 * Double(index)), value: isExpanded)
                                }
                                .offset(x: !isExpanded ? 0 : 125)
                            }
                            HStack{
                                Image(systemName: "plus")
                                    .floatingButtonStyle(prim: primaryColor, sec: secondaryColor, namespace: namespace)
                                    .animation(.easeInOut, value: isExpanded)
                                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
                                Text("Other screens")
                                    .floatingTextStyle(prim: primaryColor, sec: secondaryColor, text: "Other screens", namespace: namespace, scale: 1)
                            }.onTapGesture {
                                withAnimation{
                                    isExpanded.toggle()
                                }
                            }
                        }.position(x: 100, y: geometry.frame(in: .global).maxY - 75)
                    }
                }
            }
        }
    }
}

//Main style for custon buttons throughout the app
extension View {
    @ViewBuilder
    func mainButtonStyle(pri: Color, sec: Color, darkMode: Bool) -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.regular.tint(!darkMode ? pri.opacity(0.95) : sec.opacity(0.95)).interactive(true)) //, in: Rectangle()
                .foregroundColor(darkMode ? pri : sec)

        } else {
            self
                .background(!darkMode ? pri : sec)
                .foregroundColor(darkMode ? pri : sec)
                .buttonStyle(.borderless)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

//Extension for applying glass to items
extension View {
    @ViewBuilder
    func glassListBG(pri: Color, sec: Color, darkMode: Bool, bg: Bool = false) -> some View {
        if #available(iOS 26, *) {
            
            if bg{
                let rounding: CGFloat = 12

                self
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: rounding)
                            .foregroundStyle(Color.clear)
                            .glassEffect(darkMode ?  .clear : .clear.tint(Color.black.opacity(0.5)), in: RoundedRectangle(cornerRadius: rounding)) //.tint(sec.desaturated(amount: 0.75))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: rounding))
            }else{
                let rounding: CGFloat = 12

                self
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: rounding)
                            .foregroundStyle(darkMode ? pri.opacity(0.6) : sec.opacity(0.85))
                            //.glassEffect(.regular.tint(darkMode ? pri : sec),in: RoundedRectangle(cornerRadius: rounding))
                            .overlay(
                                RoundedRectangle(cornerRadius: rounding)
                                    .stroke(darkMode ? pri : sec, lineWidth: 1)
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: rounding))
            }
        }
        
        else{
            
            if bg{
                let rounding: CGFloat = 12

                self
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: rounding)
                            .foregroundStyle(.ultraThinMaterial)
                            .opacity(0.9)
                            .overlay(
                                RoundedRectangle(cornerRadius: rounding)
                                    .stroke(darkMode ? pri : sec, lineWidth: 1)
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: rounding))
            }else{
                let rounding: CGFloat = 12

                self
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: rounding)
                            .foregroundStyle(darkMode ? pri.opacity(0.6) : sec.opacity(0.85))
                            //.glassEffect(.regular.tint(darkMode ? pri : sec),in: RoundedRectangle(cornerRadius: rounding))
                            .overlay(
                                RoundedRectangle(cornerRadius: rounding)
                                    .stroke(darkMode ? pri : sec, lineWidth: 1)
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: rounding))
            }
        }
    }
    
}

//Specific corner radius on each individual corner
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

//Grid function
struct Grid: Shape {
    let spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Calculate the number of lines to draw.
        let numberOfHorizontalLines = Int(rect.height / spacing)
        let numberOfVerticalLines = Int(rect.height / spacing)

        // Add horizontal lines to the path.
        for index in 0...numberOfHorizontalLines {
            let y = CGFloat(index) * spacing
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.height, y: y))
        }

        // Add vertical lines to the path.
        for index in 0...numberOfVerticalLines {
            let x = CGFloat(index) * spacing
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }

        return path
    }
}

//Quick modifier for colors that desaturates them by "amount" percentage
extension Color {
    func desaturated(amount: CGFloat = 1) -> Color {
        // Convert to UIColor
        let uiColor = UIColor(self)
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)
        // Reduce saturation by the given amount
        return Color(hue: Double(hue), saturation: Double(sat * (1 - amount)), brightness: Double(bri), opacity: Double(alpha))
    }
}

