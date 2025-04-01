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
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        let darkMode: Bool = (colorScheme == .dark)

        content
            .font(.system(size: 22))
            .fontWeight(.semibold)
            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
            .padding(7)
            .contentShape(.rect(cornerRadius: 12))
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
    }
}
extension Image {
    func floatingButtonStyle(prim: Color, sec: Color) -> some View {
        modifier(FloatingButtonStyle(primaryColor: prim, secondaryColor: sec))
    }
}
struct FloatingTextStyle: ViewModifier {
    var primaryColor: Color
    var secondaryColor: Color
    @Environment(\.colorScheme) private var colorScheme

    
    func body(content: Content) -> some View {
        let darkMode: Bool = (colorScheme == .dark)

        content
            .font(.system(size: 12))
            .fontWeight(.semibold)
            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
            .padding(10)
            .contentShape(.rect(cornerRadius: 8))
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 8))
    }
}
extension Text {
    func floatingTextStyle(prim: Color, sec: Color) -> some View {
        modifier(FloatingTextStyle(primaryColor: prim, secondaryColor: sec))
    }
}

struct FloatingButtonItem: Identifiable {
    private(set) var id: UUID = .init()
    var iconSystemName: String
    var extraText: String?
    var action: () -> Void
}

struct FloatingButton: View {
    let items: [FloatingButtonItem]
    let buttonGap: CGFloat = 75
    let buttonSize: CGFloat = 35
    
    @State var isExpanded: Bool = false
    
    @EnvironmentObject var theme: ThemeColors
    
    
    var body: some View {
        ZStack {
            if isExpanded {
                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                    .onTapGesture {
                        isExpanded = false
                    }
                    .ignoresSafeArea()
            }
            
                
            GeometryReader{ geometry in
                buttonView
                    .position(x: 55, y:geometry.frame(in: .local).maxY - 30)
            }
        }.animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
    
    @ViewBuilder
    var buttonView: some View {
        let primaryColor = theme.primaryColor
        let secondaryColor  = theme.secondaryColor
                
        
        ZStack {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                ZStack{
                    Image(systemName: item.iconSystemName)
                        .floatingButtonStyle(prim: primaryColor, sec: secondaryColor)
                    Text(item.extraText ?? "")
                        .floatingTextStyle(prim: primaryColor, sec: secondaryColor)
                        .offset(x: CGFloat(item.extraText?.count ?? 10) + 65)
                }
                .opacity(isExpanded ? 1 : 0)
                .offset(x: isExpanded ? -15 : 10, y: isExpanded ? offsetY(index: index) : 0)
                .animation(.easeInOut(duration: 0.2).delay(0.03 * Double(index)), value: isExpanded)
            }.offset(y: -40)
            ZStack{
                Text("Other screens")
                    .floatingTextStyle(prim: primaryColor, sec: secondaryColor)
                    .offset(x: !isExpanded ? 75 : 85, y: 0)
                Image(systemName: "plus")
                    .floatingButtonStyle(prim: primaryColor, sec: secondaryColor)
                    .animation(.easeInOut, value: isExpanded)
                    .onTapGesture {isExpanded.toggle()}
                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
            }
        }
    }
    

    
    func offsetY(index: Int) -> CGFloat {
        return -CGFloat(index) * (buttonGap - 10) - 20
    }
}


