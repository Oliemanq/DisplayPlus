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
                .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: !darkMode)
                .glassEffectID("floatingButton", in: namespace)
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
                .mainButtonStyle(pri: primaryColor, sec: secondaryColor, darkMode: !darkMode)
                .glassEffectID("floatingText", in: namespace)
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

struct FloatingButtons<Destination: View>: View {
    let items: [FloatingButtonItem]
    let standardOffset: CGFloat = 65
    let destinationView: () -> Destination
    
    @Environment(\.colorScheme) private var colorScheme
    
    @AppStorage("showingCalibration") var showingCalibration: Bool = false
    
    @State var isExpanded: Bool = false
    @State private var isPressed: Bool = false
    @EnvironmentObject var theme: ThemeColors
    @Namespace private var namespace
    
    var body: some View {
        let primaryColor = theme.primaryColor
        let secondaryColor  = theme.secondaryColor
        
        ZStack {
            //Background when button pressed
            if #available(iOS 26, *){
                //Right button
                GeometryReader { geometry in
                    NavigationLink(destination: destinationView()) {
                        GlassEffectContainer{
                            HStack{
                                Text("Calibrate")
                                    .floatingTextStyle(prim: primaryColor, sec: secondaryColor, text: "Calibrate", namespace: namespace, scale: 0.8)
                                    .offset(x: 40, y: 5)
                                Image(systemName: "arrow.right.circle")
                                    .floatingButtonStyle(prim: primaryColor, sec: secondaryColor, namespace: namespace)
                                    .font(.system(size: 28))
                            }
                        }
                    }
                    .position(x: geometry.size.width - standardOffset - 35, y:  geometry.frame(in: .global).maxY - 75)
                }
                
                //Background when button pressed
                if isExpanded {
                    Rectangle()
                        .foregroundStyle(Color.clear)
                        .glassEffect(in: Rectangle())
                        .onTapGesture {
                            withAnimation{
                                isExpanded = false
                            }
                        }
                        .ignoresSafeArea()
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
                                            .onTapGesture {
                                                item.action()
                                                withAnimation{
                                                    isExpanded.toggle()
                                                }
                                            }
                                            .font(.system(size: 28))
                                        Text(item.extraText ?? "")
                                            .floatingTextStyle(prim: primaryColor, sec: secondaryColor, text: item.extraText ?? "", namespace: namespace, scale: 1)
                                            .onTapGesture {
                                                item.action()
                                                withAnimation{
                                                    isExpanded.toggle()
                                                }
                                            }
                                            .offset(x: -5)
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
                        HStack{
                            Text("Calibrate")
                                .floatingTextStyle(prim: primaryColor, sec: secondaryColor, text: "Calibrate", namespace: namespace, scale: 0.8)
                            Image(systemName: "arrow.right.circle")
                                .floatingButtonStyle(prim: primaryColor, sec: secondaryColor, namespace: namespace)
                                .font(.system(size: 28))
                        }
                        .onTapGesture {
                            showingCalibration = true
                        }
                        .position(x: geometry.size.width - standardOffset - 35, y:  geometry.frame(in: .global).maxY - 75)
                        .navigationDestination(isPresented: $showingCalibration) {
                            destinationView()
                        }
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

extension View {
    @ViewBuilder
    func applyGlass() -> some View {
        if #available(iOS 26, *) {
            self.glassEffect()
        }
    }
    
}

extension View {
    @ViewBuilder
    func glassListBG(pri: Color, sec: Color, darkMode: Bool) -> some View {
        if #available(iOS 26, *) {
            let insets: CGFloat = 8
            let rounding: CGFloat = 14
            
            self
                .padding(.vertical, 8)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: insets, leading: insets*1.5, bottom: insets, trailing: insets*1.5))
                .glassEffect(.regular.tint(darkMode ? pri.lighter() : sec), in: RoundedRectangle(cornerRadius: rounding))
                .clipShape(RoundedRectangle(cornerRadius: rounding))
                .listRowBackground(
                    Rectangle()
                        .foregroundStyle(Color.clear)
                        .glassEffect(.regular.tint(darkMode ? pri.lighter().opacity(0.85) : sec.darker().opacity(0.85)), in: Rectangle())
                )
            
            
        }else{
            self
                .listRowBackground(
                    VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                )
        }
    }
    
}

extension Color {
    func lighter(by amount: CGFloat = 0.25) -> Color {
        #if canImport(UIKit)
        // Try to convert to UIColor and lighten
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            print("Original: \(r), \(g), \(b)")
            print("Lighter: \(min(r + amount, 1.0)), \(min(g + amount, 1.0)), \(min(b + amount, 1.0))")
            return Color(
                red: min(r + amount, 1.0),
                green: min(g + amount, 1.0),
                blue: min(b + amount, 1.0),
                opacity: Double(a)
            )
        }
        #endif
        return self // fallback
    }
}
extension Color {
    func darker(by amount: CGFloat = 0.25) -> Color {
        #if canImport(UIKit)
        // Try to convert to UIColor and lighten
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return Color(
                red: min(r - amount, 1.0),
                green: min(g - amount, 1.0),
                blue: min(b - amount, 1.0),
                opacity: Double(a)
            )
        }
        #endif
        return self // fallback
    }
}

