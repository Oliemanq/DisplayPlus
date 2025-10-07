//  SimpleTypeExample.swift
import SwiftUI

struct SimpleTypeExample: View {
    @State var rectangleIsTargeted = false
    
    var body: some View {
        VStack {
            Text("Hello, world!")
                .draggable("hello world")
            
            Rectangle()
                // we are lightening the rectange if someone is hovering over it with the expected payload
                // to help users know that this is a target they can drop something onto
                .foregroundStyle(.secondary.opacity(rectangleIsTargeted ? 0.3 : 1))
                .dropDestination(for: String.self) { items, location in
                    guard let firstItem = items.first else {
                        // if we don't have anything in our first item,
                        // then something must have gone wrong and we want to let the system know
                        // so we return false
                        return false
                    }
                    
                    print("firstItem:", firstItem)
                    
                    //if the drop was successful, we will want to return true
                    return true
                } isTargeted: { isTargeted in
                    // this lets our state variable know that our drop destination has been targeted
                    // meaning that it could be about to recieve a transferrable object
                    rectangleIsTargeted = isTargeted
                }
        }
        .padding()
    }
}

#Preview {
    SimpleTypeExample()
}

