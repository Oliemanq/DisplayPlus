//
//  ContentView.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/4/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showViewsButton = false
    
    
    var body: some View {
        NavigationStack{
            Text("Do you want to see the other views?")
            HStack{
                Button("Yes") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showViewsButton = true
                    }
                }
                .buttonStyle(.bordered)

                
                Button("No"){
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                        showViewsButton = false
                    }
                }
                .buttonStyle(.bordered)
                
            }
            NavigationLink("HUD Debug view", destination: HUDDebug())
                .disabled(!showViewsButton)
                .padding(10)
                .buttonStyle(.borderedProminent)
                .scaleEffect(showViewsButton ? 1.5 : 1 )
            
        }
    }
}

#Preview {
    ContentView()
}
