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
                Button("Yes"){
                    showViewsButton = true
                }.frame(width: 75, height: 50)
                .buttonStyle(.borderedProminent)
                
                
                Button("No"){
                    showViewsButton = false
                }.frame(width: 75, height: 50)
                    .buttonStyle(.borderedProminent)
            }
            NavigationLink("Go to views", destination: FirstView())
                .disabled(!showViewsButton)
            
        }
    }
}

#Preview {
    ContentView()
}
