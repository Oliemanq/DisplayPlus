//
//  UIElementFunctions.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 7/16/25.
//

import SwiftUI

// NOTE: namespace must now be provided by the parent view holding @Namespace
func headerContent(
    primaryColor: Color,
    secondaryColor: Color,
    darkMode: Bool,
    BGOpacity: CGFloat,
    bleManager: G1BLEManager,
    info: InfoManager,
    namespace: Namespace.ID
) -> some View {
    if #available(iOS 26, *) {
        return GlassEffectContainer(spacing: 20){
            HStack{
                Spacer()
                VStack {
                    //Display glasses battery level if it has been updated
                    if bleManager.glassesBatteryAvg != 0.0 {
                        Text("\(info.time)")
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                    }else{
                        Text("\(info.time)")
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                    }
                    
                    HStack {
                        Text(info.getTodayDate())
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                    }
                }
                .padding(.horizontal, bleManager.connectionState == .connectedBoth ? 0 : 64)
                .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                .glassEffectID("header", in: namespace)
                
                
                Spacer()
                
                if bleManager.connectionState == .connectedBoth {
                    Spacer()
                    
                    VStack{
                        Text("Glasses - \(Int(bleManager.glassesBatteryAvg))%")
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                        
                        Text("Case - \(Int(bleManager.caseBatteryLevel))%")
                            .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                    }
                    .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                    .glassEffectID("header", in: namespace)
                    
                    Spacer()
                }
            }
        }
    }else{
        return HStack{
            Spacer()
            VStack {
                //Display glasses battery level if it has been updated
                if bleManager.glassesBatteryAvg != 0.0 {
                    Text("\(info.time)")
                        .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                }else{
                    Text("\(info.time)")
                        .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                }
                
                HStack {
                    Text(info.getTodayDate())
                        .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                }
            }
            .padding(.horizontal, bleManager.connectionState == .connectedBoth ? 0 : 64)
            .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
            
            
            Spacer()
            
            if bleManager.connectionState == .connectedBoth {
                Spacer()
                
                VStack{
                    Text("Glasses - \(Int(bleManager.glassesBatteryAvg))%")
                        .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                    
                    Text("Case - \(Int(bleManager.caseBatteryLevel))%")
                        .foregroundStyle(!darkMode ? primaryColor : secondaryColor)
                }
                .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode)
                
                Spacer()
            }
        }
    }
    
}

