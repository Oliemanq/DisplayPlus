//
//  TestButton.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/31/25.
//
import SwiftUI

let smallBGHeight: CGFloat = 55
let smallFGHeight: CGFloat = 35
let bigBGHeight: CGFloat = 75
let bigFGHeight: CGFloat = 55

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

//MARK: - Icon style for floating button
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
//MARK: - Text style for floating button
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

//MARK: - Floating button creator
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
                                            .floatingButtonStyle(prim: theme.pri, sec: theme.sec, namespace: namespace)
                                            .font(.system(size: 28))
                                        
                                        Text(item.extraText ?? "")
                                            .floatingTextStyle(prim: theme.pri, sec: theme.sec, text: item.extraText ?? "", namespace: namespace, scale: 1)
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
                                .floatingButtonStyle(prim: theme.pri, sec: theme.sec, namespace: namespace)
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
                                        .floatingButtonStyle(prim: theme.pri, sec: theme.sec, namespace: namespace)
                                    Text(item.extraText ?? "")
                                        .floatingTextStyle(prim: theme.pri, sec: theme.sec, text: item.extraText ?? "", namespace: namespace, scale: 1)
                                    Spacer()
                                }
                                .onTapGesture {
                                    item.action()
                                    withAnimation{
                                        isExpanded.toggle()
                                    }
                                }
                                .opacity(isExpanded ? 1 : 0)
                                .offset(x: isExpanded ? -15 : 10, y: isExpanded ? -standardOffset*CGFloat(index+1) : 0)
                                .animation(.easeInOut(duration: 0.2).delay(0.03 * Double(index)), value: isExpanded)
                            }
                            .offset(x: !isExpanded ? 0 : 125)
                        }
                        HStack{
                            Image(systemName: "plus")
                                .floatingButtonStyle(prim: theme.pri, sec: theme.sec, namespace: namespace)
                                .animation(.easeInOut, value: isExpanded)
                                .rotationEffect(.degrees(isExpanded ? 45 : 0))
                            Text("Other screens")
                                .floatingTextStyle(prim: theme.pri, sec: theme.sec, text: "Other screens", namespace: namespace, scale: 1)
                        }.onTapGesture {
                            withAnimation{
                                isExpanded.toggle()
                            }
                        }
                    }
                    .position(x: 100, y: geometry.frame(in: .global).maxY - 75)
                }
            }
        }
    }
}

//MARK: - General use view modifiers

//MARK: - General background modifiers
extension View {
    @ViewBuilder
    //Modifier for contextual background of items
    //If bg is true, it will just be a glass effect background without foreground color
    func ContextualBG(pri: Color, sec: Color, darkMode: Bool, bg: Bool = false, items: Int = 1, itemNum: Int = 1) -> some View {
        let rounding: CGFloat = 12
        
        let top = items > 1 && itemNum == 1
        let bottom = items > 1 && itemNum == items
        //let middle = items > 1 && (!top && !bottom)
        let alone = items == 1
        
        //Custom shape that allows the liquid glass to render properly
        //Allows items in the same "set" to look more seemless
        let shape: RoundedCorner = {
            if items > 1 {
                if top {
                    return RoundedCorner(radius: rounding, corners: [.topLeft, .topRight])
                } else if bottom {
                    return RoundedCorner(radius: rounding, corners: [.bottomLeft, .bottomRight])
                } else {
                    return RoundedCorner(radius: 0, corners: [])
                }
            } else {
                return RoundedCorner(radius: rounding, corners: .allCorners)
            }
        }()
        
        if bg {
            self
                .padding(2)
                .background(
                    Rectangle()
                        .foregroundStyle(!darkMode ? pri.opacity(0.45) : sec.opacity(0.45))
                )
                .overlay(
                    shape
                        .stroke(darkMode ? pri : sec, lineWidth: (alone ? 1 : 0))
                )
                .clipShape(shape)
        } else {
            self
                .padding(.horizontal, 6)
                .padding(.vertical, alone ? 6 : 12)
                .background(
                    Rectangle()
                        .foregroundStyle(darkMode ? pri.opacity(alone ? 0.85 : 1) : sec.opacity(alone ? 0.85 : 1))
                    //.glassEffect(.regular.tint(darkMode ? pri : sec), in: shape)
                        .overlay(
                            shape
                                .stroke(alone ? (darkMode ? pri : sec) : Color.clear, lineWidth: 1)
                        )
                )
                .clipShape(shape)
                .foregroundStyle(!darkMode ? pri : sec)
                .offset(x: 0, y: alone ? 0 : (bottom ? -10 : (top ? 10 : 0))) //Offset for multiple items
        }
    }
    
    //Main style for custon buttons throughout the app
    @ViewBuilder
    func mainButtonStyle(pri: Color, sec: Color, accent: Color, darkMode: Bool) -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(darkMode ? .regular.interactive(true) : .regular.tint(pri).interactive(true))
                .foregroundColor(accent)

        } else {
            self
                .background(!darkMode ? pri : sec)
                .foregroundColor(darkMode ? pri : sec)
                .buttonStyle(.borderless)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    //Modifier for custom toolbar background and sizing
    @ViewBuilder
    func ToolBarBG(pri: Color, sec: Color, darkMode: Bool) -> some View {
        if #available(iOS 26, *) {
            
            self
                .foregroundStyle(!darkMode ? pri : sec)
                .padding(8)
                .glassEffect(.clear.interactive())
        }else{
            let rounding: CGFloat = 12
            
            self
                .foregroundStyle(!darkMode ? pri : sec)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: rounding)
                        .foregroundStyle(darkMode ? pri.opacity(0.6) : sec.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: rounding)
                                .stroke(!darkMode ? pri : sec, lineWidth: 0.5)
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: rounding))
        }
    }
    
    //Modifier for items in settings view
    @ViewBuilder
    func settingsItem(themeIn: ThemeColors) -> some View {
        let screenWidth = UIScreen.main.bounds.width
        //let screenHeight = UIScreen.main.bounds.height
        
        HStack{
            VStack(alignment: .leading){
                self
                    .tint(themeIn.accent)
            }
            .frame(width: screenWidth * 0.825, height: 35)
            .ContextualBG(pri: themeIn.pri, sec: themeIn.sec, darkMode: themeIn.darkMode)
        }
        .frame(width: screenWidth * 0.9, height: 55)
        .ContextualBG(pri: themeIn.pri, sec: themeIn.sec, darkMode: themeIn.darkMode, bg: true)
    }
    
    @ViewBuilder
    func homeItem(themeIn: ThemeColors) -> some View {
        let screenWidth = UIScreen.main.bounds.width
        //let screenHeight = UIScreen.main.bounds.height
        
        HStack{
            VStack(alignment: .leading){
                self
            }
            .frame(width: screenWidth * 0.825, height: bigFGHeight*2)
            .ContextualBG(pri: themeIn.pri, sec: themeIn.sec, darkMode: themeIn.darkMode)
        }
        .frame(width: screenWidth * 0.9, height: bigBGHeight*1.75)
        .ContextualBG(pri: themeIn.pri, sec: themeIn.sec, darkMode: themeIn.darkMode, bg: true)
    }
    @ViewBuilder
    func infoItem(themeIn: ThemeColors, subItem: Bool = false, items: Int = 1, itemNum: Int = 1) -> some View {
        let screenWidth = UIScreen.main.bounds.width
        //let screenHeight = UIScreen.main.bounds.height
        
        HStack{
            VStack(alignment: .center){
                self
            }
            .frame(width: screenWidth * 0.825, height: subItem ?  smallFGHeight : bigFGHeight)
            .ContextualBG(pri: themeIn.pri, sec: themeIn.sec, darkMode: themeIn.darkMode, items: items, itemNum: itemNum)
        }
        .frame(width: screenWidth * 0.9, height: subItem ? smallBGHeight : bigBGHeight)
        .ContextualBG(pri: themeIn.pri, sec: themeIn.sec, darkMode: themeIn.darkMode, bg: true, items: items, itemNum: itemNum)
        
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

//MARK: - Background grid
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

func backgroundGrid(themeIn: ThemeColors) -> some View {
    let theme: ThemeColors = themeIn
    
    // State variables to hold the customizable properties of the grid.
    @State var lineColor: Color = theme.darkMode ? theme.pri : theme.sec
    @State var lineWidth: CGFloat = 1
    @State var spacing: CGFloat = 10
    
    
    return ZStack{
        if theme.darkMode {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: theme.sec, location: 0.0), // Lighter color at top-left
                    .init(color: theme.pri, location: 0.5),  // Transition to darker
                    .init(color: theme.pri, location: 1.0)   // Darker color for the rest
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: theme.pri, location: 0.0), // Darker color at top-left
                    .init(color: theme.sec, location: 0.5),  // Transition to lighter
                    .init(color: theme.sec, location: 1.0)   // Lighter color for the rest
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        Grid(spacing: spacing)
            .stroke(lineColor, lineWidth: lineWidth)
            .offset(x: -300, y: 25)
            .rotationEffect(.degrees(45))
        
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: theme.darkMode ? theme.pri.opacity(0.95) : theme.sec.opacity(0.95), location: 0.05),
                .init(color: Color.clear, location: 0.1)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    .edgesIgnoringSafeArea(.all)
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
    func moreSaturated(amount: CGFloat = 1) -> Color {
        // Convert to UIColor
        let uiColor = UIColor(self)
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)
        // Reduce saturation by the given amount
        return Color(hue: Double(hue), saturation: Double(sat * (1 + amount)), brightness: Double(bri), opacity: Double(alpha))
    }
    
    func darker(by percentage: CGFloat = 0.2) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return Color(UIColor(hue: hue, saturation: saturation, brightness: brightness * (1 - percentage), alpha: alpha))
        }
        return self
    }
}

//MARK: - Preview
struct PreviewVars: View {
    var body: some View {
        let theme = ThemeColors()
        
        ZStack{
            backgroundGrid(themeIn: theme)
            ScrollView(.vertical){
                VStack{
                    Text("Main button style")
                        .frame(width: 150, height: 40)
                        .mainButtonStyle(pri: theme.pri, sec: theme.sec, accent: theme.accent, darkMode: theme.darkMode)
                    Text("Rounded corner style")
                        .frame(width: 200, height: 40)
                        .foregroundStyle(theme.sec)
                        .background(
                            RoundedCorner(radius: 24 ,corners: [.topLeft, .bottomRight])
                        )
                    Text("Background glass")
                        .foregroundStyle(theme.sec)
                        .ContextualBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode, bg: true)
                    
                    Button("Toggle UI colors"){
                        theme.darkMode.toggle()
                    }
                    .frame(width: 150, height: 40)
                    .mainButtonStyle(pri: theme.pri, sec: theme.sec, accent: theme.accent, darkMode: theme.darkMode)
                    
                    Text("Toolbar background")
                        .ToolBarBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                }
                .padding(.top, 250)
            }
        }
    }
}

#Preview {
    PreviewVars()
}

