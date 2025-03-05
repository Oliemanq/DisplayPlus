//
//  SecondView.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/4/25.
//

import SwiftUI

struct SecondView: View {
    var body: some View {
        NavigationStack{
            List {
                NavigationLink("First View", destination: FirstView())
            }
        }.navigationTitle(Text("Second View"))
            .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SecondView()
}
