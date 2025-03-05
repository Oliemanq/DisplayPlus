//
//  FirstView.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/4/25.
//

import SwiftUI

struct FirstView: View {
    var body: some View {
        NavigationStack{
            VStack{
                List{
                    NavigationLink("Second View", destination: SecondView())
                }
            }
        }.navigationTitle(Text("First View"))
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
        
        
    }
}

#Preview {
    FirstView()
}
