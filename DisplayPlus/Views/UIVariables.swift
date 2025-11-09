//
//  TestButton.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/31/25.
//
import SwiftUI

let BGHeight: CGFloat = 55

//MARK: - General background modifiers
extension View {
    @ViewBuilder
    //Modifier for contextual background of items
    //If bg is true, it will just be a glass effect background without foreground color
    func ContextualBG(themeIn: ThemeColors, bg: Bool = false, items: Int = 1, itemNum: Int = 1) -> some View {
        let rounding: CGFloat = 12
        
        let top = items > 1 && itemNum == 1
        let bottom = items > 1 && itemNum == items
        //let middle = items > 1 && (!top && !bottom)
        let alone = items == 1
        
        let darkMode = themeIn.darkMode
        let pri = themeIn.dark
        let sec = themeIn.light
        let priLightAlt = themeIn.darkSec
        let secDarkAlt = themeIn.lightSec
        //        let accentLight = themeIn.accentLight
        //        let accentDark = themeIn.accentDark
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
                .padding(.vertical, alone ? 4 : -4)
                .padding(.horizontal, 4)
                .background(
                    shape
                        .foregroundStyle(darkMode ? pri : sec)
                )
                .overlay(
                    shape
                        .stroke(priLightAlt, lineWidth: 0.5)
                )
                .clipShape(shape)
                .overlay(
                    Group {
                        if items > 1 {
                            if top {
                                // cover bottom interior stroke for the top item
                                VStack {
                                    Spacer()
                                    Rectangle()
                                        .fill(darkMode ? pri : sec)
                                        .frame(height: 0.6)
                                }
                                .clipShape(shape)
                            } else if bottom {
                                // cover top interior stroke for the bottom item
                                VStack {
                                    Rectangle()
                                        .fill(darkMode ? pri : sec)
                                        .frame(height: 0.6)
                                    Spacer()
                                }
                                .clipShape(shape)
                            } else {
                                // middle items: cover both top and bottom interior strokes
                                VStack(spacing: 0) {
                                    Rectangle()
                                        .fill(darkMode ? pri : sec)
                                        .frame(height: 0.6)
                                    Spacer()
                                    Rectangle()
                                        .fill(darkMode ? pri : sec)
                                        .frame(height: 0.6)
                                }
                                .clipShape(shape)
                            }
                        }
                    }
                )
        } else {
            self
                .padding(.horizontal, 8)
                .padding(.vertical, alone ? 8 : 6)
                .background(
                    shape
                        .foregroundStyle(darkMode ? priLightAlt : secDarkAlt)
                        .overlay(
                            shape
                                .stroke(priLightAlt, lineWidth: 0.5)
                        )
                )
                .clipShape(shape)
                .foregroundStyle(!darkMode ? priLightAlt : secDarkAlt)
                .overlay(
                    Group {
                        if items > 1 {
                            if top {
                                VStack {
                                    Spacer()
                                    Rectangle()
                                        .fill(darkMode ? priLightAlt : secDarkAlt)
                                        .frame(height: 0.6)
                                }
                                .clipShape(shape)
                            } else if bottom {
                                VStack {
                                    Rectangle()
                                        .fill(darkMode ? priLightAlt : secDarkAlt)
                                        .frame(height: 0.6)
                                    Spacer()
                                }
                                .clipShape(shape)
                            } else {
                                VStack(spacing: 0) {
                                    Rectangle()
                                        .fill(darkMode ? priLightAlt : secDarkAlt)
                                        .frame(height: 0.6)
                                    Spacer()
                                    Rectangle()
                                        .fill(darkMode ? priLightAlt : secDarkAlt)
                                        .frame(height: 0.6)
                                }
                                .clipShape(shape)
                            }
                        }
                    }
                )
        }
    }
    
    //Main style for custon buttons throughout the app
    @ViewBuilder
    func mainButtonStyle(themeIn: ThemeColors) -> some View {
        let darkMode = themeIn.darkMode
        let pri = themeIn.dark
        let sec = themeIn.light
        let priLightAlt = themeIn.darkSec
        let secDarkAlt = themeIn.lightSec
        //        let accentLight = themeIn.accentLight
        //        let accentDark = themeIn.accentDark
        
        if #available(iOS 26, *) {
            self
                .glassEffect(.regular.interactive())
                .foregroundStyle(!darkMode ? pri : sec)
            //.foregroundColor(accent)
            
        } else {
            self
                .background(!darkMode ? priLightAlt : secDarkAlt)
                .foregroundStyle(darkMode ? pri : sec)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    @ViewBuilder
    func settingsButton(themeIn: ThemeColors) -> some View {
        self
            .padding(.vertical, 8)
            .padding(.horizontal, 24)
            .font(.system(size: 24))
            .mainButtonStyle(themeIn: themeIn)
    }
    @ViewBuilder
    func settingsButtonText(themeIn: ThemeColors) -> some View {
        let shape = RoundedCorner(radius: 8, corners: [.topLeft, .bottomLeft])
        
        let padding: CGFloat = 8
        let buttonSidePadding: CGFloat = 36
        let offset: CGFloat = -42
        
        if #available(iOS 26, *) {
            self
                .padding(padding)
                .padding(.trailing, buttonSidePadding)
                .background(
                    shape
                        .foregroundStyle(themeIn.darkMode ? themeIn.darkSec : themeIn.lightSec)
                        .glassEffect(.regular, in: shape)
                )
                .padding(.trailing, offset)
        } else {
            self
                .padding(padding)
                .padding(.trailing, buttonSidePadding)
                .background(
                    shape
                        .foregroundStyle(themeIn.darkMode ? themeIn.darkSec : themeIn.lightSec)
                )
                .padding(.trailing, offset)
        }
    }
    
    //Modifier for custom toolbar background and sizing
    @ViewBuilder
    func ToolBarBG(pri: Color, sec: Color, darkMode: Bool) -> some View {
        if #available(iOS 26, *) {
            
            self
                .foregroundStyle(!darkMode ? pri : sec)
                .padding(8)
                .glassEffect(darkMode ? .clear.interactive() : .regular.interactive())
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
    
    @ViewBuilder
    func homeItem(themeIn: ThemeColors, subItem: Bool = false, small: Bool = false, height: CGFloat = 0) -> some View {
        let screenWidth = UIScreen.main.bounds.width
        //let screenHeight = UIScreen.main.bounds.height
        
        if subItem { //Non-background item
            HStack{
                self
            }
            .ContextualBG(themeIn: themeIn)
        }else{ //Background item
            HStack{
                self
            }
            .frame(width: screenWidth * 0.9, height: (height == 0 ? 75*(small ? 1.25 : 1.75) : height))
            .padding(.horizontal, 6)
            .ContextualBG(themeIn: themeIn, bg: true)
        }
    }
    
    @ViewBuilder
    func settingsItem(themeIn: ThemeColors, items: Int = 1, itemNum: Int = 1) -> some View {
        let screenWidth = UIScreen.main.bounds.width
        
        self
            .font(themeIn.bodyFont)
            .padding(.horizontal, 12)
            .tint(themeIn.darkMode ? themeIn.accentDark : themeIn.accentLight)
            .frame(width: screenWidth * 0.9, height: BGHeight)
            .ContextualBG(themeIn: themeIn, bg: true, items: items, itemNum: itemNum)
    }
        
    @ViewBuilder
    func editorBlock(themeIn: ThemeColors) -> some View {
        let shape: RoundedCorner = {
            let cornerRounding: CGFloat = 10
            return RoundedCorner(radius: cornerRounding, corners: [.allCorners])
        }()
        
        self
            .foregroundStyle(!themeIn.darkMode ? themeIn.darkSec : themeIn.lightSec)
            .background {
                shape
                    .foregroundStyle(themeIn.darkMode ? themeIn.darkSec : themeIn.lightSec)
                    .overlay(
                        shape
                            .stroke(themeIn.darkMode ? Color.clear : themeIn.darkSec, lineWidth: 1)
                    )
            }
            .clipShape(shape)
    }
    
    //MARK: - Text modifiers
    @ViewBuilder
    func explanationText(themeIn: ThemeColors, width: CGFloat = .infinity) -> some View {
        self
            .font(.custom("TrebuchetMS",size: 14))
            .foregroundStyle(themeIn.darkMode ? themeIn.lightSec : themeIn.darkSec)
            .frame(maxWidth: width)
    }
    
    @ViewBuilder
    func pageHeaderText(themeIn: ThemeColors) -> some View {
        self
            .font(themeIn.headerFont)
            .foregroundStyle(themeIn.darkMode ? themeIn.light : themeIn.dark)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(themeIn.darkMode ? themeIn.darkTert : themeIn.lightTert)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(!themeIn.darkMode ? themeIn.darkSec : themeIn.lightSec, lineWidth: 0.35)
                    )
            )
            .padding(.top, 5)
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
    @State private var theme = ThemeColors()
    @State private var refreshID = UUID()

    var body: some View {
        ZStack {
            (theme.darkMode ? theme.backgroundDark : theme.backgroundLight)
                .ignoresSafeArea()

            ScrollView(.vertical) {
                Text("Page Header text")
                    .pageHeaderText(themeIn: theme)
                Text("Settings Explanation text")
                    .explanationText(themeIn: theme)
                
            }
            .id(refreshID)
            .padding(.top, 250)
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
                DispatchQueue.main.async {
                    theme.darkMode.toggle()
                    refreshID = UUID()
                    print("toggle dark mode \(theme.darkMode)")
                }
            }
        }
    }
}

#Preview {
    PreviewVars()
}

